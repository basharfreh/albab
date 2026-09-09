import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory


@pytest.mark.django_db
class TestStatusTransitions:
    def test_published_to_sold_allowed(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(
            reverse("listing-status", args=[listing.id]), {"status": "sold"}, format="json"
        )
        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == ListingStatus.SOLD

    def test_published_to_rented_and_paused_allowed(self):
        owner = UserFactory(role="owner")
        for target in ["rented", "paused"]:
            listing = ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
            client = APIClient()
            client.force_authenticate(owner)
            response = client.post(
                reverse("listing-status", args=[listing.id]), {"status": target}, format="json"
            )
            assert response.status_code == 200

    def test_sold_to_published_rejected(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.SOLD)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(
            reverse("listing-status", args=[listing.id]), {"status": "published"}, format="json"
        )
        assert response.status_code == 400
        listing.refresh_from_db()
        assert listing.status == ListingStatus.SOLD

    def test_paused_to_published_allowed_republish(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.PAUSED)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(
            reverse("listing-status", args=[listing.id]), {"status": "published"}, format="json"
        )
        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == ListingStatus.PUBLISHED

    def test_draft_has_no_owner_initiated_transitions(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.DRAFT)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(
            reverse("listing-status", args=[listing.id]), {"status": "published"}, format="json"
        )
        assert response.status_code == 400

    def test_invalid_status_value_rejected(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(
            reverse("listing-status", args=[listing.id]), {"status": "not-a-status"}, format="json"
        )
        assert response.status_code == 400
