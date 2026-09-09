from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.engagement.models import Conversation, Message, Notification


class ConversationListingSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField()
    cover_thumbnail = serializers.SerializerMethodField()

    def get_cover_thumbnail(self, listing):
        cover = next((img for img in listing.images.all() if img.is_cover), None) or next(
            iter(listing.images.all()), None
        )
        if cover and cover.thumbnail:
            return cover.thumbnail.url
        return None


class ConversationSerializer(serializers.ModelSerializer):
    listing = ConversationListingSerializer(read_only=True)
    counterpart = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ["id", "listing", "counterpart", "last_message", "unread_count", "last_message_at"]

    def get_counterpart(self, obj):
        request_user = self.context["request"].user
        other = obj.owner if request_user.id == obj.seeker_id else obj.seeker
        return UserSerializer(other).data

    def get_last_message(self, obj):
        # obj.messages is prefetched (ascending, the model's default ordering) by the view —
        # indexing the cached list avoids a fresh per-row query that .order_by() would trigger.
        messages = list(obj.messages.all())
        return MessageSerializer(messages[-1]).data if messages else None

    def get_unread_count(self, obj):
        request_user = self.context["request"].user
        return sum(
            1
            for message in obj.messages.all()
            if message.read_at is None and message.sender_id != request_user.id
        )


class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)

    class Meta:
        model = Message
        fields = ["id", "conversation", "sender", "body", "read_at", "created_at"]
        read_only_fields = ["id", "conversation", "sender", "read_at", "created_at"]


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "kind", "title", "body", "data", "read_at", "created_at"]
        read_only_fields = fields
