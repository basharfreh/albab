import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.engagement.models import Notification, NotificationKind


@pytest.mark.django_db
class TestBroadcastNotifications:
    def test_non_admin_cannot_broadcast(self):
        client = APIClient()
        client.force_authenticate(UserFactory(role="seeker"))
        response = client.post(
            reverse("admin-notifications-broadcast"),
            {"title": "تجربة", "target": "all"},
        )
        assert response.status_code == 403

    def test_broadcast_to_all_reaches_every_user(self):
        UserFactory.create_batch(3, role="seeker")
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(
            reverse("admin-notifications-broadcast"),
            {"title": "صيانة مجدولة", "body": "سيتم إيقاف الموقع للصيانة.", "target": "all"},
        )
        assert response.status_code == 200
        # 3 seekers + the admin sending it = 4 users total in the DB.
        assert response.data["sent"] == 4
        assert Notification.objects.filter(kind=NotificationKind.BROADCAST).count() == 4

    def test_broadcast_by_role_reaches_only_that_role(self):
        UserFactory.create_batch(2, role="owner")
        UserFactory.create_batch(3, role="seeker")
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(
            reverse("admin-notifications-broadcast"),
            {"title": "تحديث للملاك", "target": "role", "role": "owner"},
        )
        assert response.status_code == 200
        assert response.data["sent"] == 2
        assert Notification.objects.filter(kind=NotificationKind.BROADCAST).count() == 2

    def test_broadcast_role_target_without_role_is_rejected(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(
            reverse("admin-notifications-broadcast"),
            {"title": "تحديث", "target": "role"},
        )
        assert response.status_code == 400

    def test_broadcast_to_one_user(self):
        target_user = UserFactory(role="seeker")
        UserFactory(role="seeker")
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(
            reverse("admin-notifications-broadcast"),
            {"title": "رسالة خاصة", "target": "user", "user_id": target_user.id},
        )
        assert response.status_code == 200
        assert response.data["sent"] == 1
        notification = Notification.objects.get(kind=NotificationKind.BROADCAST)
        assert notification.user_id == target_user.id

    def test_broadcast_to_nonexistent_user_is_a_404_not_a_silent_no_op(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(
            reverse("admin-notifications-broadcast"),
            {"title": "رسالة", "target": "user", "user_id": 999999},
        )
        assert response.status_code == 404
