import pytest
from django.urls import reverse
from rest_framework.exceptions import ValidationError
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import ListingQuotaSettings, ListingStatus, Neighborhood
from apps.catalog.services.quota import check_quota
from apps.catalog.tests.factories import ListingFactory, NeighborhoodFactory


@pytest.mark.django_db
class TestAdminNeighborhoods:
    def test_non_admin_cannot_list(self):
        client = APIClient()
        client.force_authenticate(UserFactory(role="seeker"))
        assert client.get(reverse("admin-neighborhood-list")).status_code == 403

    def test_admin_can_create_update_and_deactivate(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        create_response = client.post(
            reverse("admin-neighborhood-list"),
            {
                "name_ar": "حي جديد",
                "name_en": "New District",
                "slug": "new-district",
                "center_lat": "36.372000",
                "center_lng": "37.517000",
            },
        )
        assert create_response.status_code == 201
        neighborhood_id = create_response.data["id"]

        update_response = client.patch(
            reverse("admin-neighborhood-detail", args=[neighborhood_id]),
            {"is_active": False},
        )
        assert update_response.status_code == 200
        assert update_response.data["is_active"] is False
        assert Neighborhood.objects.get(pk=neighborhood_id).is_active is False

    def test_admin_list_includes_inactive_neighborhoods(self):
        NeighborhoodFactory(is_active=False)
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.get(reverse("admin-neighborhood-list"))
        assert response.status_code == 200
        assert response.data["count"] == 1

    def test_deleting_a_neighborhood_in_use_is_rejected_not_500(self):
        neighborhood = NeighborhoodFactory()
        ListingFactory(neighborhood=neighborhood)
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.delete(reverse("admin-neighborhood-detail", args=[neighborhood.id]))
        assert response.status_code == 400
        assert Neighborhood.objects.filter(pk=neighborhood.id).exists()

    def test_deleting_an_unused_neighborhood_succeeds(self):
        neighborhood = NeighborhoodFactory()
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.delete(reverse("admin-neighborhood-detail", args=[neighborhood.id]))
        assert response.status_code == 204
        assert not Neighborhood.objects.filter(pk=neighborhood.id).exists()


@pytest.mark.django_db
class TestAdminQuotaSettings:
    def test_non_admin_cannot_view_quotas(self):
        client = APIClient()
        client.force_authenticate(UserFactory(role="owner"))
        assert client.get(reverse("admin-quota-settings")).status_code == 403

    def test_admin_can_read_default_quotas(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.get(reverse("admin-quota-settings"))
        assert response.status_code == 200
        assert response.data == {"seeker": 0, "owner": 10, "agency": 100}

    def test_admin_can_update_quotas_and_it_takes_effect(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.patch(reverse("admin-quota-settings"), {"owner": 1})
        assert response.status_code == 200
        assert response.data["owner"] == 1

        owner = UserFactory(role="owner")
        ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        with pytest.raises(ValidationError):
            check_quota(owner)


@pytest.mark.django_db
def test_quota_solo_is_a_single_row():
    first = ListingQuotaSettings.get_solo()
    second = ListingQuotaSettings.get_solo()
    assert first.pk == second.pk == 1
    assert ListingQuotaSettings.objects.count() == 1
