import django_filters
from django.db.models import Q

from apps.catalog.models import Listing, ListingPurpose, PropertyType


class BedroomsFilter(django_filters.CharFilter):
    """`n` means exactly n, `n+` means at least n."""

    def filter(self, qs, value):
        if not value:
            return qs
        exact = value.endswith("+")
        raw = value[:-1] if exact else value
        try:
            n = int(raw)
        except ValueError:
            return qs.none()
        return qs.filter(bedrooms__gte=n) if exact else qs.filter(bedrooms=n)


class ListingFilterSet(django_filters.FilterSet):
    purpose = django_filters.ChoiceFilter(choices=ListingPurpose.choices)
    property_type = django_filters.ChoiceFilter(choices=PropertyType.choices)
    neighborhood = django_filters.NumberFilter(field_name="neighborhood_id")
    min_price = django_filters.NumberFilter(field_name="price", lookup_expr="gte")
    max_price = django_filters.NumberFilter(field_name="price", lookup_expr="lte")
    min_area = django_filters.NumberFilter(field_name="area_sqm", lookup_expr="gte")
    max_area = django_filters.NumberFilter(field_name="area_sqm", lookup_expr="lte")
    bedrooms = BedroomsFilter()
    bathrooms = django_filters.NumberFilter(field_name="bathrooms")
    q = django_filters.CharFilter(method="filter_q")
    bbox = django_filters.CharFilter(method="filter_bbox")
    ordering = django_filters.OrderingFilter(
        fields=(("is_featured", "is_featured"), ("published_at", "published_at")),
    )

    class Meta:
        model = Listing
        fields = []

    def filter_q(self, queryset, name, value):
        return queryset.filter(
            Q(title__icontains=value)
            | Q(description__icontains=value)
            | Q(landmark__icontains=value)
            | Q(neighborhood__name_ar__icontains=value)
        )

    def filter_bbox(self, queryset, name, value):
        try:
            min_lng, min_lat, max_lng, max_lat = (float(part) for part in value.split(","))
        except (ValueError, AttributeError):
            return queryset.none()
        return queryset.filter(lat__range=(min_lat, max_lat), lng__range=(min_lng, max_lng))
