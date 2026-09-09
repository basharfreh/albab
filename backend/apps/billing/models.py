from django.conf import settings
from django.db import models

from apps.catalog.models import Listing


class PromotionPackage(models.Model):
    name_ar = models.CharField(max_length=100)
    name_en = models.CharField(max_length=100, blank=True)
    days = models.PositiveSmallIntegerField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["days"]

    def __str__(self):
        return f"{self.name_ar} ({self.days}d)"


class PromotionStatus(models.TextChoices):
    PENDING = "pending", "pending"
    ACTIVE = "active", "active"
    EXPIRED = "expired", "expired"


class Promotion(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="promotions")
    package = models.ForeignKey(
        PromotionPackage, on_delete=models.PROTECT, related_name="promotions"
    )
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(
        max_length=10, choices=PromotionStatus.choices, default=PromotionStatus.PENDING
    )

    class Meta:
        ordering = ["-id"]

    def __str__(self):
        return f"Promotion(listing={self.listing_id}, status={self.status})"


class TransactionMethod(models.TextChoices):
    CASH = "cash", "cash"
    MANUAL = "manual", "manual"


class TransactionStatus(models.TextChoices):
    PENDING = "pending", "pending"
    COMPLETED = "completed", "completed"


class Transaction(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="transactions"
    )
    promotion = models.ForeignKey(Promotion, on_delete=models.CASCADE, related_name="transactions")
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default="USD")
    method = models.CharField(max_length=10, choices=TransactionMethod.choices)
    reference = models.CharField(max_length=100, blank=True)
    status = models.CharField(
        max_length=10, choices=TransactionStatus.choices, default=TransactionStatus.COMPLETED
    )
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="recorded_transactions",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Transaction({self.amount} {self.currency}, status={self.status})"
