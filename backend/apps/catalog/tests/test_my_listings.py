import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory


@pytest.mark.django_db
class TestMyListingsSerializer:
    """`MyListingSerializer` — the extra fields P10's my-listings/stats screens need on top
    of the plain `ListingCardSerializer` (status chip, rejection reason, views/contacts)."""

    def test_response_carries_status_and_counts(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(
            owner=owner,
            status=ListingStatus.PUBLISHED,
            views_count=7,
            contacts_count=2,
        )
        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("my-listings"))
        assert response.status_code == 200
        row = next(r for r in response.data["results"] if r["id"] == listing.id)
        assert row["status"] == "published"
        assert row["views_count"] == 7
        assert row["contacts_count"] == 2
        assert row["rejection_reason"] in (None, "")

    def test_rejected_listing_carries_its_reason(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(
            owner=owner, status=ListingStatus.REJECTED, rejection_reason="صورة غير واضحة"
        )
        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("my-listings"))
        row = next(r for r in response.data["results"] if r["id"] == listing.id)
        assert row["status"] == "rejected"
        assert row["rejection_reason"] == "صورة غير واضحة"

    def test_status_filter_still_works(self):
        owner = UserFactory(role="owner")
        ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        ListingFactory(owner=owner, status=ListingStatus.PENDING)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("my-listings"), {"status": "pending"})
        assert response.status_code == 200
        assert all(r["status"] == "pending" for r in response.data["results"])

    def test_another_owners_listings_are_not_visible(self):
        owner = UserFactory(role="owner")
        other = UserFactory(role="owner")
        ListingFactory(owner=other, status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.get(reverse("my-listings"))
        assert response.data["count"] == 0
