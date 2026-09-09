from django.conf import settings
from django.db import models

from apps.catalog.models import Listing


class ReportStatus(models.TextChoices):
    OPEN = "open", "open"
    CLOSED = "closed", "closed"


class ListingReport(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="reports")
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="listing_reports"
    )
    reason = models.CharField(max_length=100)
    note = models.CharField(max_length=500, blank=True)
    status = models.CharField(
        max_length=10, choices=ReportStatus.choices, default=ReportStatus.OPEN
    )
    handled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="handled_reports",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"ListingReport(listing={self.listing_id}, status={self.status})"


class ModerationActionType(models.TextChoices):
    APPROVE = "approve", "approve"
    REJECT = "reject", "reject"


class ModerationAction(models.Model):
    listing = models.ForeignKey(
        Listing, on_delete=models.CASCADE, related_name="moderation_actions"
    )
    admin = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    action = models.CharField(max_length=10, choices=ModerationActionType.choices)
    reason = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"ModerationAction({self.action}, listing={self.listing_id})"
