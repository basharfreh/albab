from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.catalog.models import Listing
from apps.common.permissions import IsAdminRole
from apps.moderation.models import ListingReport
from apps.moderation.serializers import (
    AdminListingSerializer,
    ListingReportSerializer,
    ReportCreateSerializer,
)
from apps.moderation.services.moderation import (
    approve_listing,
    close_report,
    reject_listing,
    report_listing,
)


class ReportCreateView(APIView):
    """UC-20: report an inappropriate listing."""

    permission_classes = [IsAuthenticated]

    def post(self, request, listing_id):
        listing = get_object_or_404(Listing, pk=listing_id)
        serializer = ReportCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report_listing(listing=listing, reporter=request.user, **serializer.validated_data)
        return Response({"detail": "تم إرسال البلاغ."}, status=201)


class AdminListingQueueView(generics.ListAPIView):
    """GET /admin/listings/?status=pending — the moderation queue."""

    serializer_class = AdminListingSerializer
    permission_classes = [IsAdminRole]
    filterset_fields = ["status"]

    def get_queryset(self):
        return (
            Listing.objects.select_related("neighborhood", "owner")
            .prefetch_related("images")
            .order_by("-created_at")
        )


class ApproveListingView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        listing = get_object_or_404(Listing, pk=pk)
        approve_listing(listing=listing, admin=request.user)
        return Response(AdminListingSerializer(listing, context={"request": request}).data)


class RejectListingView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        listing = get_object_or_404(Listing, pk=pk)
        reject_listing(listing=listing, admin=request.user, reason=request.data.get("reason", ""))
        return Response(AdminListingSerializer(listing, context={"request": request}).data)


class AdminReportsListView(generics.ListAPIView):
    """UC-58: abuse reports queue."""

    serializer_class = ListingReportSerializer
    permission_classes = [IsAdminRole]
    filterset_fields = ["status"]
    queryset = ListingReport.objects.select_related(
        "listing__neighborhood", "listing__owner", "reporter"
    ).prefetch_related("listing__images")


class ReportCloseView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        report = get_object_or_404(ListingReport, pk=pk)
        close_report(report=report, admin=request.user)
        return Response(ListingReportSerializer(report).data)
