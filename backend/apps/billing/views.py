from django.db.models.deletion import ProtectedError
from django.shortcuts import get_object_or_404
from rest_framework import generics, viewsets
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from apps.billing.models import Promotion, PromotionPackage, Transaction
from apps.billing.serializers import (
    PromotionCreateSerializer,
    PromotionPackageSerializer,
    PromotionSerializer,
    TransactionSerializer,
)
from apps.billing.services import record_transaction
from apps.catalog.models import Listing
from apps.common.permissions import IsAdminRole


class AdminPromotionPackageViewSet(viewsets.ModelViewSet):
    """UC-56: promotion packages CRUD — previously only reachable via Django admin (P3),
    which left the dashboard's "create a promotion" flow with no way to list packages for a
    picker. Closes that gap."""

    serializer_class = PromotionPackageSerializer
    permission_classes = [IsAdminRole]
    queryset = PromotionPackage.objects.all()

    def destroy(self, request, *args, **kwargs):
        # `Promotion.package` is `on_delete=PROTECT` — same reasoning as
        # `AdminNeighborhoodViewSet.destroy` (see catalog/views.py): deactivate instead of
        # deleting a package that's already been used.
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            raise ValidationError(
                "لا يمكن حذف هذه الباقة لوجود إعلانات مرتبطة بها. قم بإلغاء تفعيلها بدلاً من ذلك."
            )


class AdminPromotionListCreateView(generics.ListCreateAPIView):
    """UC-56: active promotions (`?status=` filter — also how المعاملات' record-payment
    dialog finds `pending` promotions to bill)."""

    permission_classes = [IsAdminRole]
    queryset = Promotion.objects.select_related("listing", "listing__owner", "package")
    filterset_fields = ["status"]

    def get_serializer_class(self):
        return PromotionCreateSerializer if self.request.method == "POST" else PromotionSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        listing = get_object_or_404(Listing, pk=serializer.validated_data["listing"])
        package = get_object_or_404(PromotionPackage, pk=serializer.validated_data["package"])
        promotion = Promotion.objects.create(listing=listing, package=package)
        return Response(PromotionSerializer(promotion).data, status=201)


class AdminTransactionListCreateView(generics.ListCreateAPIView):
    """UC-57: manually recorded payments. A "completed" one activates its promotion.
    `?status=`/`?created_at__gte=`/`?created_at__lte=` (ISO datetimes) for the brief's
    "filters by date and status"."""

    permission_classes = [IsAdminRole]
    serializer_class = TransactionSerializer
    queryset = Transaction.objects.select_related("promotion__listing", "user")
    filterset_fields = {"status": ["exact"], "created_at": ["gte", "lte"]}

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = dict(serializer.validated_data)
        promotion = data.pop("promotion")
        user = data.pop("user")
        transaction = record_transaction(
            user=user, promotion=promotion, recorded_by=request.user, **data
        )
        return Response(TransactionSerializer(transaction).data, status=201)
