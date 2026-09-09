from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.analytics.services.events import record_event
from apps.catalog.models import Listing
from apps.engagement.models import Conversation, Notification
from apps.engagement.serializers import (
    ConversationSerializer,
    MessageSerializer,
    NotificationSerializer,
)
from apps.engagement.services.notify import notify_new_message


class ConversationListCreateView(generics.ListCreateAPIView):
    """UC-40: one conversation per (listing, seeker) pair."""

    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        from django.db.models import Q

        return (
            Conversation.objects.filter(Q(seeker=user) | Q(owner=user))
            .select_related("listing", "seeker", "owner")
            .prefetch_related("listing__images", "messages")
        )

    def create(self, request, *args, **kwargs):
        listing_id = request.data.get("listing")
        if not listing_id:
            raise ValidationError({"listing": ["مطلوب."]})
        listing = get_object_or_404(Listing, pk=listing_id)
        if listing.owner_id == request.user.id:
            raise ValidationError({"listing": ["لا يمكنك مراسلة نفسك بخصوص عقارك."]})

        conversation, _ = Conversation.objects.get_or_create(
            listing=listing, seeker=request.user, defaults={"owner": listing.owner}
        )
        serializer = self.get_serializer(conversation)
        return Response(serializer.data, status=201)


class ConversationMessagesView(generics.ListCreateAPIView):
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]

    def get_conversation(self):
        conversation = get_object_or_404(Conversation, pk=self.kwargs["conversation_id"])
        if self.request.user.id not in (conversation.seeker_id, conversation.owner_id):
            raise PermissionDenied("لا يمكنك الوصول إلى هذه المحادثة.")
        return conversation

    def get_queryset(self):
        conversation = self.get_conversation()
        conversation.messages.filter(read_at__isnull=True).exclude(sender=self.request.user).update(
            read_at=timezone.now()
        )
        return conversation.messages.select_related("sender")

    def create(self, request, *args, **kwargs):
        conversation = self.get_conversation()
        body = (request.data.get("body") or "").strip()
        if not body:
            raise ValidationError({"body": ["الرسالة فارغة."]})

        message = conversation.messages.create(sender=request.user, body=body)
        conversation.last_message_at = message.created_at
        conversation.save(update_fields=["last_message_at"])

        notify_new_message(message)
        record_event(
            listing=conversation.listing,
            kind="message",
            user=request.user,
            ip_hash=None,
        )

        serializer = self.get_serializer(message)
        return Response(serializer.data, status=201)


class NotificationListView(generics.ListAPIView):
    """UC-41: notifications list with unread badge."""

    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


class NotificationReadAllView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(user=request.user, read_at__isnull=True).update(
            read_at=timezone.now()
        )
        return Response({"detail": "تم تعليم كل الإشعارات كمقروءة."})


class NotificationMarkReadView(APIView):
    """`POST /notifications/{id}/read/` — marks one notification read. Not in brief §8's
    fixed endpoint list (only the bulk `read-all/` is) — added for P10, whose own "Do" list
    needs a single-notification "tap marks it read" alongside the separate bulk app-bar
    action, which `read-all/` alone can't express without marking every other unread
    notification read as a tap side effect. See docs/PROGRESS.md's P10 entry."""

    permission_classes = [IsAuthenticated]

    def post(self, request, notification_id):
        notification = get_object_or_404(Notification, pk=notification_id, user=request.user)
        if notification.read_at is None:
            notification.read_at = timezone.now()
            notification.save(update_fields=["read_at"])
        return Response(NotificationSerializer(notification).data)
