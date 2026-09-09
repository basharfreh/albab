import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory


@pytest.mark.django_db
class TestListingPermissions:
    def test_anonymous_can_list_and_retrieve_published(self):
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        assert client.get(reverse("listing-list")).status_code == 200
        assert client.get(reverse("listing-detail", args=[listing.id])).status_code == 200

    def test_anonymous_cannot_retrieve_draft(self):
        listing = ListingFactory(status=ListingStatus.DRAFT)
        client = APIClient()
        response = client.get(reverse("listing-detail", args=[listing.id]))
        assert response.status_code == 404

    def test_owner_can_retrieve_own_draft(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.DRAFT)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("listing-detail", args=[listing.id]))
        assert response.status_code == 200

    def test_other_user_cannot_see_someone_elses_draft(self):
        owner = UserFactory(role="owner")
        other = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.DRAFT)
        client = APIClient()
        client.force_authenticate(other)
        response = client.get(reverse("listing-detail", args=[listing.id]))
        assert response.status_code == 404

    def test_non_owner_cannot_edit(self):
        owner = UserFactory(role="owner")
        other = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.DRAFT)
        client = APIClient()
        client.force_authenticate(other)
        response = client.patch(
            reverse("listing-detail", args=[listing.id]), {"title": "محاولة"}, format="json"
        )
        assert response.status_code == 404

    def test_anonymous_cannot_create(self):
        client = APIClient()
        response = client.post(reverse("listing-list"), {}, format="json")
        assert response.status_code == 401

    def test_pending_listing_cannot_be_edited(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.PENDING)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.patch(
            reverse("listing-detail", args=[listing.id]), {"title": "تعديل"}, format="json"
        )
        assert response.status_code == 400
