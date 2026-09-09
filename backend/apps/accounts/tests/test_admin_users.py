import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory


@pytest.mark.django_db
class TestAdminUsers:
    def test_non_admin_cannot_list_users(self):
        client = APIClient()
        client.force_authenticate(UserFactory(role="seeker"))
        assert client.get(reverse("admin-users")).status_code == 403

    def test_admin_can_search_users_by_name(self):
        admin = UserFactory(role="admin")
        UserFactory(name="أحمد الحسين")
        UserFactory(name="سامر الزهراء")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.get(reverse("admin-users"), {"q": "الحسين"})
        assert response.status_code == 200
        assert response.data["count"] == 1

    def test_admin_can_block_a_user(self):
        admin = UserFactory(role="admin")
        target = UserFactory()
        client = APIClient()
        client.force_authenticate(admin)
        response = client.post(reverse("admin-user-block", args=[target.id]), {"blocked": True})
        assert response.status_code == 200
        target.refresh_from_db()
        assert target.is_blocked is True

    def test_block_persists_reason_and_unblock_clears_it(self):
        admin = UserFactory(role="admin")
        target = UserFactory()
        client = APIClient()
        client.force_authenticate(admin)
        response = client.post(
            reverse("admin-user-block", args=[target.id]),
            {"blocked": True, "reason": "شكاوى متكررة"},
        )
        assert response.status_code == 200
        assert response.data["block_reason"] == "شكاوى متكررة"
        target.refresh_from_db()
        assert target.block_reason == "شكاوى متكررة"

        response = client.post(reverse("admin-user-block", args=[target.id]), {"blocked": False})
        assert response.status_code == 200
        assert response.data["block_reason"] == ""
        target.refresh_from_db()
        assert target.block_reason == ""

    def test_admin_can_change_role(self):
        admin = UserFactory(role="admin")
        target = UserFactory(role="seeker")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.post(reverse("admin-user-role", args=[target.id]), {"role": "owner"})
        assert response.status_code == 200
        target.refresh_from_db()
        assert target.role == "owner"
