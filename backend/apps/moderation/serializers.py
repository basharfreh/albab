from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.catalog.serializers import ListingDetailSerializer
from apps.moderation.models import ListingReport


class AdminListingSerializer(ListingDetailSerializer):
    class Meta(ListingDetailSerializer.Meta):
        fields = ListingDetailSerializer.Meta.fields + [
            "status",
            "rejection_reason",
            "created_at",
        ]


class ReportCreateSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=100)
    note = serializers.CharField(max_length=500, required=False, allow_blank=True)


class ListingReportSerializer(serializers.ModelSerializer):
    listing = AdminListingSerializer(read_only=True)
    reporter = UserSerializer(read_only=True)

    class Meta:
        model = ListingReport
        fields = ["id", "listing", "reporter", "reason", "note", "status", "created_at"]
        read_only_fields = fields
