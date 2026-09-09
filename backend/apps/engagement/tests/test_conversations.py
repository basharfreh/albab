import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.tests.factories import ListingFactory
from apps.engagement.models import Conversation, Notification


@pytest.mark.django_db
class TestConversations:
    def test_starting_a_conversation_is_idempotent(self):
        owner = UserFactory(role="owner")
        seeker = UserFactory(role="seeker")
        listing = ListingFactory(owner=owner)
        client = APIClient()
        client.force_authenticate(seeker)

        first = client.post(reverse("conversations"), {"listing": listing.id})
        second = client.post(reverse("conversations"), {"listing": listing.id})
        assert first.status_code == 201
        assert second.status_code == 201
        assert Conversation.objects.filter(listing=listing, seeker=seeker).count() == 1

    def test_owner_cannot_message_own_listing(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(reverse("conversations"), {"listing": listing.id})
        assert response.status_code == 400

    def test_sending_a_message_notifies_the_other_party(self):
        owner = UserFactory(role="owner")
        seeker = UserFactory(role="seeker")
        listing = ListingFactory(owner=owner)
        client = APIClient()
        client.force_authenticate(seeker)
        conversation_id = client.post(reverse("conversations"), {"listing": listing.id}).data["id"]

        response = client.post(
            reverse("conversation-messages", args=[conversation_id]), {"body": "مرحباً"}
        )
        assert response.status_code == 201
        assert Notification.objects.filter(user=owner, kind="new_message").exists()

    def test_fetching_messages_marks_them_read(self):
        owner = UserFactory(role="owner")
        seeker = UserFactory(role="seeker")
        listing = ListingFactory(owner=owner)
        conversation = Conversation.objects.create(listing=listing, seeker=seeker, owner=owner)
        conversation.messages.create(sender=seeker, body="مرحباً")

        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("conversation-messages", args=[conversation.id]))
        assert response.status_code == 200

        message = conversation.messages.get()
        assert message.read_at is not None

    def test_stranger_cannot_access_conversation(self):
        owner = UserFactory(role="owner")
        seeker = UserFactory(role="seeker")
        stranger = UserFactory(role="seeker")
        listing = ListingFactory(owner=owner)
        conversation = Conversation.objects.create(listing=listing, seeker=seeker, owner=owner)

        client = APIClient()
        client.force_authenticate(stranger)
        response = client.get(reverse("conversation-messages", args=[conversation.id]))
        assert response.status_code == 403


@pytest.mark.django_db
class TestNotifications:
    def test_read_all_marks_every_notification_read(self):
        user = UserFactory()
        Notification.objects.create(user=user, kind="new_message", title="test")
        Notification.objects.create(user=user, kind="new_message", title="test2")

        client = APIClient()
        client.force_authenticate(user)
        response = client.post(reverse("notifications-read-all"))
        assert response.status_code == 200
        assert not user.notifications.filter(read_at__isnull=True).exists()

    def test_me_exposes_unread_counts(self):
        owner = UserFactory(role="owner")
        seeker = UserFactory(role="seeker")
        listing = ListingFactory(owner=owner)
        conversation = Conversation.objects.create(listing=listing, seeker=seeker, owner=owner)
        conversation.messages.create(sender=seeker, body="مرحباً")
        Notification.objects.create(user=owner, kind="new_message", title="test")

        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("auth-me"))
        assert response.data["unread_messages"] == 1
        assert response.data["unread_notifications"] == 1

    def test_mark_one_read_leaves_others_unread(self):
        user = UserFactory()
        first = Notification.objects.create(user=user, kind="new_message", title="test")
        second = Notification.objects.create(user=user, kind="new_message", title="test2")

        client = APIClient()
        client.force_authenticate(user)
        response = client.post(reverse("notification-read", args=[first.id]))
        assert response.status_code == 200
        assert response.data["read_at"] is not None

        first.refresh_from_db()
        second.refresh_from_db()
        assert first.read_at is not None
        assert second.read_at is None

    def test_cannot_mark_another_users_notification_read(self):
        owner = UserFactory()
        other = UserFactory()
        notification = Notification.objects.create(user=owner, kind="new_message", title="test")

        client = APIClient()
        client.force_authenticate(other)
        response = client.post(reverse("notification-read", args=[notification.id]))
        assert response.status_code == 404
