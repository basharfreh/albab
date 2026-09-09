from django.shortcuts import get_object_or_404
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.analytics.models import ListingEventKind
from apps.analytics.services.events import compute_ip_hash, record_event
from apps.analytics.services.stats import (
    admin_by_type_breakdown,
    admin_kpis,
    admin_visits_series,
    owner_listing_stats,
)
from apps.catalog.models import Listing
from apps.common.permissions import IsAdminRole

PUBLIC_EVENT_KINDS = {
    ListingEventKind.VIEW,
    ListingEventKind.CALL,
    ListingEventKind.WHATSAPP,
    ListingEventKind.SHARE,
}


class ListingEventCreateView(APIView):
    """POST /listings/{id}/events/ — anonymous allowed, throttled per-IP for views."""

    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "events"

    def post(self, request, listing_id):
        listing = get_object_or_404(Listing, pk=listing_id)
        kind = request.data.get("kind")
        if kind not in PUBLIC_EVENT_KINDS:
            raise ValidationError({"kind": ["قيمة غير صالحة."]})

        user = request.user if request.user.is_authenticated else None
        record_event(listing=listing, kind=kind, user=user, ip_hash=compute_ip_hash(request))
        return Response(status=201)


class OwnerListingStatsView(APIView):
    """UC-37: GET /me/listings/stats/?days=30"""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        days = int(request.query_params.get("days", 30))
        return Response(owner_listing_stats(request.user, days=days))


class AdminKpisView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        return Response(admin_kpis())


class AdminVisitsView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        days = int(request.query_params.get("days", 30))
        return Response(admin_visits_series(days=days))


class AdminByTypeView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        return Response(admin_by_type_breakdown())
