from rest_framework import serializers

from apps.billing.models import Promotion, PromotionPackage, Transaction


class PromotionPackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionPackage
        fields = ["id", "name_ar", "name_en", "days", "price", "is_active"]


class PromotionSerializer(serializers.ModelSerializer):
    package = PromotionPackageSerializer(read_only=True)
    listing_title = serializers.CharField(source="listing.title", read_only=True)

    class Meta:
        model = Promotion
        fields = [
            "id",
            "listing",
            "listing_title",
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
    class Meta:
        model = Transaction
        fields = [
            "id",
            "user",
            "promotion",
            "amount",
            "currency",
            "method",
            "reference",
            "status",
            "recorded_by",
            "created_at",
        ]
        read_only_fields = ["recorded_by", "created_at"]
