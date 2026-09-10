from rest_framework import serializers

from apps.accounts.models import User
from apps.catalog.models import Listing, ListingImage, ListingQuotaSettings, Neighborhood


class NeighborhoodSerializer(serializers.ModelSerializer):
    class Meta:
        model = Neighborhood
        fields = ["id", "name_ar", "name_en", "slug", "center_lat", "center_lng"]


class AdminNeighborhoodSerializer(serializers.ModelSerializer):
    """UC-59: unlike the public `NeighborhoodSerializer`, exposes `is_active`/`sort_order`
    (the admin manages both) and is writable."""

    class Meta:
        model = Neighborhood
        fields = [
            "id",
            "name_ar",
            "name_en",
            "slug",
            "center_lat",
            "center_lng",
            "is_active",
            "sort_order",
        ]


class QuotaSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingQuotaSettings
        fields = ["seeker", "owner", "agency"]


class ListingImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingImage
        fields = ["id", "image", "thumbnail", "sort_order", "is_cover"]
        read_only_fields = ["thumbnail"]


class OwnerBlockSerializer(serializers.ModelSerializer):
    """A listing's public owner block. whatsapp_phone falls back to phone when unset."""

    whatsapp_phone = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "name", "avatar", "role", "phone", "whatsapp_phone", "created_at"]

    def get_whatsapp_phone(self, obj):
        return obj.whatsapp_phone or obj.phone


class ListingCardSerializer(serializers.ModelSerializer):
    cover_thumbnail = serializers.SerializerMethodField()
    neighborhood_name = serializers.CharField(source="neighborhood.name_ar", default=None)
    images_count = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Listing
        fields = [
            "id",
            "cover_thumbnail",
            "title",
            "neighborhood_name",
            "landmark",
            "price",
            "currency",
            "is_negotiable",
            "area_sqm",
            "bedrooms",
            "bathrooms",
            "images_count",
            "purpose",
            "property_type",
            "is_featured",
            "is_favorited",
        ]

    def get_cover_thumbnail(self, obj):
        images = list(obj.images.all())
        cover = next((img for img in images if img.is_cover), images[0] if images else None)
        if cover and cover.thumbnail:
            request = self.context.get("request")
            url = cover.thumbnail.url
            return request.build_absolute_uri(url) if request else url
        return None

    def get_images_count(self, obj):
        return len(obj.images.all())

    def get_is_favorited(self, obj):
        return bool(getattr(obj, "is_favorited", False))


class ListingDetailSerializer(ListingCardSerializer):
    images = ListingImageSerializer(many=True, read_only=True)
    owner = OwnerBlockSerializer(read_only=True)

    class Meta(ListingCardSerializer.Meta):
        fields = ListingCardSerializer.Meta.fields + [
            "description",
            "images",
            "lat",
            "lng",
            "owner",
        ]


class MyListingSerializer(ListingCardSerializer):
    """`GET /me/listings/` — the owner's own view of their listing. Adds `status` (for the
    status-tabbed list, brief P10 item 2), `rejection_reason` (shown inline on a rejected
    row), and `views_count`/`contacts_count` (the row's "views count", and doubling as the
    stats screen's per-listing breakdown — brief P10 item 3 — since neither figure has any
    other per-listing endpoint). `AdminListingSerializer` (apps/moderation) already adds
    `status`/`rejection_reason`/`created_at` on top of the full detail shape for the admin
    queue; this is the lighter, card-shaped equivalent for the owner's own list."""

    class Meta(ListingCardSerializer.Meta):
        fields = ListingCardSerializer.Meta.fields + [
            "status",
            "rejection_reason",
            "views_count",
            "contacts_count",
            "created_at",
            "published_at",
        ]


class ListingMapSerializer(serializers.ModelSerializer):
    class Meta:
        model = Listing
        fields = ["id", "lat", "lng", "property_type", "purpose", "price"]


class ListingWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Listing
        fields = [
            "id",
            "title",
            "description",
            "property_type",
            "purpose",
            "price",
            "currency",
            "is_negotiable",
            "area_sqm",
            "bedrooms",
            "bathrooms",
            "neighborhood",
            "landmark",
            "lat",
            "lng",
            "status",
        ]
        read_only_fields = ["id", "status"]
