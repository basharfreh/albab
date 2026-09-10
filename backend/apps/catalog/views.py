from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import BooleanField, Exists, OuterRef, Q, Value
from django.db.models.deletion import ProtectedError
from django.shortcuts import get_object_or_404
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import generics, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.catalog.filters import ListingFilterSet
from apps.catalog.models import (
    Favorite,
    Listing,
    ListingImage,
    ListingQuotaSettings,
    ListingStatus,
    Neighborhood,
)
from apps.catalog.serializers import (
    AdminNeighborhoodSerializer,
    ListingCardSerializer,
    ListingDetailSerializer,
    ListingImageSerializer,
    ListingMapSerializer,
    ListingWriteSerializer,
    MyListingSerializer,
    NeighborhoodSerializer,
    QuotaSettingsSerializer,
)
from apps.catalog.services.geo import nearest_neighborhood, search_places
from apps.catalog.services.images import (
    MAX_IMAGES_PER_LISTING,
    make_thumbnail,
    validate_image_file,
)
from apps.catalog.services.listing_status import transition_status
from apps.catalog.services.quota import check_quota
from apps.common.permissions import IsAdminRole

EDITABLE_STATUSES = {ListingStatus.DRAFT, ListingStatus.REJECTED, ListingStatus.PUBLISHED}
MAP_MARKER_LIMIT = 500


def _favorited_annotation(queryset, user):
    if user.is_authenticated:
        return queryset.annotate(
            is_favorited=Exists(Favorite.objects.filter(user=user, listing=OuterRef("pk")))
        )
    return queryset.annotate(is_favorited=Value(False, output_field=BooleanField()))


class AdminNeighborhoodViewSet(viewsets.ModelViewSet):
    """UC-59: full CRUD, including inactive neighborhoods (unlike the public,
    active-only `NeighborhoodListView`)."""

    serializer_class = AdminNeighborhoodSerializer
    permission_classes = [IsAdminRole]
    queryset = Neighborhood.objects.all()

    def destroy(self, request, *args, **kwargs):
        # `Listing.neighborhood` is `on_delete=PROTECT` — deleting a neighborhood still in use
        # would otherwise surface as an unhandled 500 (`ProtectedError` isn't a DRF exception).
        # Deactivating (`is_active=False`) is the intended way to retire one; delete is only for
        # a neighborhood that was never actually used.
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            raise ValidationError(
                "لا يمكن حذف هذا الحي لوجود عقارات مرتبطة به. قم بإلغاء تفعيله بدلاً من ذلك."
            )


class AdminQuotaSettingsView(generics.RetrieveUpdateAPIView):
    """UC-59: `GET`/`PATCH /admin/settings/quotas/` — the one settings row `services/quota.py`
    reads (see `ListingQuotaSettings.get_solo`)."""

    serializer_class = QuotaSettingsSerializer
    permission_classes = [IsAdminRole]

    def get_object(self):
        return ListingQuotaSettings.get_solo()


@method_decorator(cache_page(60), name="dispatch")
class NeighborhoodListView(generics.ListAPIView):
    serializer_class = NeighborhoodSerializer
    permission_classes = [AllowAny]
    pagination_class = None
    queryset = Neighborhood.objects.filter(is_active=True)


@method_decorator(cache_page(60), name="map")
class ListingViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend]
    filterset_class = ListingFilterSet

    def get_permissions(self):
        if self.action in ("list", "retrieve", "map"):
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action == "list":
            return ListingCardSerializer
        if self.action == "retrieve":
            return ListingDetailSerializer
        if self.action == "map":
            return ListingMapSerializer
        return ListingWriteSerializer

    def get_queryset(self):
        base = Listing.objects.select_related("neighborhood", "owner").prefetch_related("images")
        user = self.request.user

        if self.action == "retrieve":
            if user.is_authenticated:
                base = base.filter(Q(status=ListingStatus.PUBLISHED) | Q(owner=user))
            else:
                base = base.filter(status=ListingStatus.PUBLISHED)
        elif self.action in ("list", "map"):
            base = base.filter(status=ListingStatus.PUBLISHED)
        else:
            base = base.filter(owner=user) if user.is_authenticated else base.none()

        return _favorited_annotation(base, user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user, status=ListingStatus.DRAFT)

    def perform_update(self, serializer):
        if serializer.instance.status not in EDITABLE_STATUSES:
            raise ValidationError("لا يمكن تعديل هذا العقار في حالته الحالية.")
        serializer.save()

    @action(detail=False, methods=["get"])
    def map(self, request):
        queryset = self.filter_queryset(self.get_queryset())
        total = queryset.count()
        markers = queryset[:MAP_MARKER_LIMIT]
        return Response(
            {
                "results": ListingMapSerializer(markers, many=True).data,
                "truncated": total > MAP_MARKER_LIMIT,
            }
        )

    @action(detail=True, methods=["post"])
    def submit(self, request, pk=None):
        listing = self.get_object()
        if listing.status not in (ListingStatus.DRAFT, ListingStatus.REJECTED):
            raise ValidationError("لا يمكن إرسال هذا العقار للمراجعة من حالته الحالية.")

        errors = {}
        if not listing.images.exists():
            errors["images"] = ["أضف صورة واحدة على الأقل."]
        if listing.price is None:
            errors["price"] = ["السعر مطلوب."]
        if listing.lat is None or listing.lng is None:
            errors["location"] = ["الموقع مطلوب."]
        if listing.neighborhood_id is None:
            errors["neighborhood"] = ["الحي مطلوب."]
        if errors:
            raise ValidationError(errors)

        check_quota(request.user)

        listing.status = ListingStatus.PENDING
        listing.rejection_reason = ""
        listing.save(update_fields=["status", "rejection_reason", "updated_at"])
        return Response(
            ListingDetailSerializer(listing, context=self.get_serializer_context()).data
        )

    @action(detail=True, methods=["post"])
    def status(self, request, pk=None):
        listing = self.get_object()
        target = request.data.get("status")
        if target not in ListingStatus.values:
            raise ValidationError({"status": ["قيمة الحالة غير صالحة."]})
        transition_status(listing, target)
        return Response(
            ListingDetailSerializer(listing, context=self.get_serializer_context()).data
        )


class MyListingsView(generics.ListAPIView):
    serializer_class = MyListingSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["status"]

    def get_queryset(self):
        base = (
            Listing.objects.filter(owner=self.request.user)
            .select_related("neighborhood")
            .prefetch_related("images")
        )
        return _favorited_annotation(base, self.request.user)


class FavoriteListCreateView(generics.ListCreateAPIView):
    serializer_class = ListingCardSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        listing_ids = Favorite.objects.filter(user=self.request.user).values_list(
            "listing_id", flat=True
        )
        base = (
            Listing.objects.filter(id__in=listing_ids)
            .select_related("neighborhood")
            .prefetch_related("images")
        )
        return base.annotate(is_favorited=Value(True, output_field=BooleanField()))

    def create(self, request, *args, **kwargs):
        listing_id = request.data.get("listing")
        if not listing_id:
            raise ValidationError({"listing": ["مطلوب."]})
        listing = get_object_or_404(Listing, pk=listing_id, status=ListingStatus.PUBLISHED)
        Favorite.objects.get_or_create(user=request.user, listing=listing)
        listing.is_favorited = True
        serializer = self.get_serializer(listing)
        return Response(serializer.data, status=201)


class FavoriteDeleteView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return get_object_or_404(
            Favorite, user=self.request.user, listing_id=self.kwargs["listing_id"]
        )


class ListingImageListCreateView(generics.ListCreateAPIView):
    serializer_class = ListingImageSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    pagination_class = None

    def get_listing(self):
        return get_object_or_404(Listing, pk=self.kwargs["listing_id"], owner=self.request.user)

    def get_queryset(self):
        return ListingImage.objects.filter(listing=self.get_listing())

    def create(self, request, *args, **kwargs):
        listing = self.get_listing()
        if listing.images.count() >= MAX_IMAGES_PER_LISTING:
            raise ValidationError(
                {"image": [f"الحد الأقصى {MAX_IMAGES_PER_LISTING} صورة لكل عقار."]}
            )

        uploaded = request.FILES.get("image")
        if uploaded is None:
            raise ValidationError({"image": ["الرجاء إرفاق صورة."]})
        try:
            validate_image_file(uploaded)
        except DjangoValidationError as exc:
            raise ValidationError({"image": exc.messages}) from exc

        thumbnail = make_thumbnail(uploaded)
        uploaded.seek(0)

        is_first = not listing.images.exists()
        wants_cover = str(request.data.get("is_cover", "")).lower() in ("true", "1")
        is_cover = is_first or wants_cover
        if is_cover:
            listing.images.update(is_cover=False)

        image = ListingImage.objects.create(
            listing=listing,
            image=uploaded,
            thumbnail=thumbnail,
            sort_order=listing.images.count(),
            is_cover=is_cover,
        )
        serializer = self.get_serializer(image)
        return Response(serializer.data, status=201)


class ListingImageDetailView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        listing = get_object_or_404(Listing, pk=self.kwargs["listing_id"], owner=self.request.user)
        return get_object_or_404(ListingImage, pk=self.kwargs["image_id"], listing=listing)

    def perform_destroy(self, instance):
        was_cover = instance.is_cover
        listing = instance.listing
        instance.delete()
        if was_cover:
            next_image = listing.images.order_by("sort_order").first()
            if next_image:
                next_image.is_cover = True
                next_image.save(update_fields=["is_cover"])


class ListingImageReorderView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, listing_id):
        listing = get_object_or_404(Listing, pk=listing_id, owner=request.user)
        order = request.data.get("order")
        if not isinstance(order, list) or not order:
            raise ValidationError({"order": ["الرجاء إرسال قائمة بمعرفات الصور بالترتيب المطلوب."]})
        images = {img.id: img for img in listing.images.all()}
        if set(order) != set(images.keys()):
            raise ValidationError({"order": ["يجب أن تتضمن القائمة كل صور العقار مرة واحدة فقط."]})
        for index, image_id in enumerate(order):
            images[image_id].sort_order = index
            images[image_id].save(update_fields=["sort_order"])
        return Response(ListingImageSerializer(listing.images.all(), many=True).data)


class GeoSearchView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "geo"

    def get(self, request):
        query = request.query_params.get("q", "").strip()
        if not query:
            raise ValidationError({"q": ["الرجاء إدخال نص للبحث."]})
        return Response(search_places(query))


class GeoReverseView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "geo"

    def get(self, request):
        try:
            lat = float(request.query_params["lat"])
            lng = float(request.query_params["lng"])
        except (KeyError, ValueError):
            raise ValidationError({"detail": "الرجاء تحديد lat وlng صحيحين."})
        neighborhood = nearest_neighborhood(lat, lng)
        if neighborhood is None:
            return Response(status=204)
        return Response(NeighborhoodSerializer(neighborhood).data)
