import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.common.models import StaticPage


@pytest.mark.django_db
class TestAdminStaticPages:
    def test_non_admin_cannot_list(self):
        client = APIClient()
        client.force_authenticate(UserFactory(role="seeker"))
        assert client.get(reverse("admin-static-page-list")).status_code == 403

    def test_admin_can_create_update_and_delete(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        create_response = client.post(
            reverse("admin-static-page-list"),
            {"slug": "about", "title_ar": "من نحن", "body_ar": "الباب العقاري..."},
        )
        assert create_response.status_code == 201
        page_id = create_response.data["id"]

        update_response = client.patch(
            reverse("admin-static-page-detail", args=[page_id]),
            {"body_ar": "نص محدث"},
        )
        assert update_response.status_code == 200
        assert update_response.data["body_ar"] == "نص محدث"

        delete_response = client.delete(reverse("admin-static-page-detail", args=[page_id]))
        assert delete_response.status_code == 204
        assert not StaticPage.objects.filter(pk=page_id).exists()

    def test_slug_must_be_unique(self):
        StaticPage.objects.create(slug="terms", title_ar="الشروط")
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.post(
            reverse("admin-static-page-list"), {"slug": "terms", "title_ar": "شروط أخرى"}
        )
        assert response.status_code == 400
