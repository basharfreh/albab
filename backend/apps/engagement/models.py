from django.conf import settings
from django.db import models

from apps.catalog.models import Listing
from apps.common.models import TimeStampedModel


class Conversation(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="conversations")
    seeker = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="conversations_as_seeker"
    )
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="conversations_as_owner"
    )
    last_message_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = [("listing", "seeker")]
        ordering = ["-last_message_at"]

    def __str__(self):
        return f"Conversation(listing={self.listing_id}, seeker={self.seeker_id})"


class Message(TimeStampedModel):
    conversation = models.ForeignKey(
        Conversation, on_delete=models.CASCADE, related_name="messages"
    )
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    body = models.TextField()
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Message(conversation={self.conversation_id}, sender={self.sender_id})"


class NotificationKind(models.TextChoices):
    LISTING_APPROVED = "listing_approved", "listing_approved"
    LISTING_REJECTED = "listing_rejected", "listing_rejected"
    NEW_MESSAGE = "new_message", "new_message"
    PROMOTION_EXPIRING = "promotion_expiring", "promotion_expiring"
    BROADCAST = "broadcast", "broadcast"


class Notification(TimeStampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications"
    )
    kind = models.CharField(max_length=30, choices=NotificationKind.choices)
    title = models.CharField(max_length=200)
    body = models.CharField(max_length=500, blank=True)
    data = models.JSONField(default=dict, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["user", "read_at"])]

    def __str__(self):
        return f"Notification({self.kind}, user={self.user_id})"


class DeviceTokenPlatform(models.TextChoices):
    ANDROID = "android", "android"
    IOS = "ios", "ios"
    WEB = "web", "web"


class DeviceToken(TimeStampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="device_tokens"
    )
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=10, choices=DeviceTokenPlatform.choices)

    def __str__(self):
        return f"DeviceToken({self.platform}, user={self.user_id})"
