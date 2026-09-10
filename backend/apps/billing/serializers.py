from rest_framework import serializers

from apps.billing.models import Promotion, PromotionPackage, Transaction


class PromotionPackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionPackage
        fields = ["id", "name_ar", "name_en", "days", "price", "is_active"]


class PromotionSerializer(serializers.ModelSerializer):
    package = PromotionPackageSerializer(read_only=True)
    listing_title = serializers.CharField(source="listing.title", read_only=True)
    # المعاملات' "record payment" dialog picks a pending promotion and needs to know who to
    # bill for it without a second user-lookup round trip — the payer is always the listing's
    # owner, so surface it straight from here.
    listing_owner = serializers.IntegerField(source="listing.owner_id", read_only=True)
    listing_owner_name = serializers.CharField(source="listing.owner.name", read_only=True)

    class Meta:
        model = Promotion
        fields = [
            "id",
            "listing",
            "listing_title",
            "listing_owner",
            "listing_owner_name",
            "package",
            "starts_at",
            "ends_at",
            "status",
        ]
        read_only_fields = ["starts_at", "ends_at", "status"]


class PromotionCreateSerializer(serializers.Serializer):
    listing = serializers.IntegerField()
    package = serializers.IntegerField()


class TransactionSerializer(serializers.ModelSerializer):
    # Read-only display fields (P11) so المعاملات' table doesn't have to show raw ids —
    # this serializer is otherwise write-focused (POST creates a transaction), unlike
    # `PromotionSerializer`'s fully nested `package`.
    user_name = serializers.CharField(source="user.name", read_only=True)
    listing_title = serializers.CharField(source="promotion.listing.title", read_only=True)

    class Meta:
        model = Transaction
        fields = [
            "id",
            "user",
            "user_name",
            "promotion",
            "listing_title",
            "amount",
            "currency",
            "method",
            "reference",
            "status",
            "recorded_by",
            "created_at",
        ]
        read_only_fields = ["recorded_by", "created_at"]
