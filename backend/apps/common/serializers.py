from rest_framework import serializers

from apps.common.models import StaticPage


class StaticPageSerializer(serializers.ModelSerializer):
    class Meta:
        model = StaticPage
        fields = ["id", "slug", "title_ar", "title_en", "body_ar", "body_en", "updated_at"]
        read_only_fields = ["updated_at"]
