from django.conf import settings
from django.db import models

from apps.catalog.models import Listing


class ListingEventKind(models.TextChoices):
    VIEW = "view", "view"
    CALL = "call", "call"
    WHATSAPP = "whatsapp", "whatsapp"
    MESSAGE = "message", "message"
    SHARE = "share", "share"


class ListingEvent(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="events")
    kind = models.CharField(max_length=10, choices=ListingEventKind.choices)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="listing_events",
    )
    ip_hash = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["listing", "kind", "created_at"]),
            models.Index(fields=["listing", "ip_hash", "kind", "created_at"]),
        ]

    def __str__(self):
        return f"ListingEvent({self.kind}, listing={self.listing_id})"


class ListingDailyStat(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="daily_stats")
    date = models.DateField()
    views = models.PositiveIntegerField(default=0)
    contacts = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = [("listing", "date")]
        ordering = ["-date"]

    def __str__(self):
        return f"ListingDailyStat({self.listing_id}, {self.date})"
