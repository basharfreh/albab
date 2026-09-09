from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.response import Response

from apps.billing.models import Promotion, Transaction
from apps.billing.serializers import (
    PromotionCreateSerializer,
    PromotionSerializer,
    TransactionSerializer,
)
from apps.billing.services import record_transaction
from apps.catalog.models import Listing
from apps.common.permissions import IsAdminRole


class AdminPromotionListCreateView(generics.ListCreateAPIView):
    """UC-56: active promotions. Packages themselves are managed via Django admin for now."""

    permission_classes = [IsAdminRole]
    queryset = Promotion.objects.select_related("listing", "package")

    def get_serializer_class(self):
        return PromotionCreateSerializer if self.request.method == "POST" else PromotionSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        listing = get_object_or_404(Listing, pk=serializer.validated_data["listing"])
        from apps.billing.models import PromotionPackage

        package = get_object_or_404(PromotionPackage, pk=serializer.validated_data["package"])
        promotion = Promotion.objects.create(listing=listing, package=package)
        return Response(PromotionSerializer(promotion).data, status=201)


class AdminTransactionListCreateView(generics.ListCreateAPIView):
    """UC-57: manually recorded payments. A "completed" one activates its promotion."""

    permission_classes = [IsAdminRole]
    serializer_class = TransactionSerializer
    queryset = Transaction.objects.select_related("promotion", "user")

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
