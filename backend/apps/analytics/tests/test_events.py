import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.analytics.models import ListingEvent
from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory


@pytest.mark.django_db
class TestListingEvents:
    def test_posting_same_view_twice_within_an_hour_increments_once(self):
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        url = reverse("listing-events", args=[listing.id])

        assert client.post(url, {"kind": "view"}).status_code == 201
        assert client.post(url, {"kind": "view"}).status_code == 201

        listing.refresh_from_db()
        assert listing.views_count == 1
        assert ListingEvent.objects.filter(listing=listing, kind="view").count() == 1

    def test_call_and_whatsapp_increment_contacts_count(self):
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        url = reverse("listing-events", args=[listing.id])

        client.post(url, {"kind": "call"})
        client.post(url, {"kind": "whatsapp"})

        listing.refresh_from_db()
        assert listing.contacts_count == 2

    def test_invalid_kind_rejected(self):
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        response = client.post(reverse("listing-events", args=[listing.id]), {"kind": "message"})
        assert response.status_code == 400


@pytest.mark.django_db
class TestOwnerStats:
    def test_owner_can_view_own_stats(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(owner)
        client.post(reverse("listing-events", args=[listing.id]), {"kind": "view"})

        response = client.get(reverse("my-listings-stats"), {"days": 7})
        assert response.status_code == 200
        assert response.data["totals"]["views"] == 1

    def test_stats_totals_split_contacts_by_channel(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(owner)
        events_url = reverse("listing-events", args=[listing.id])
        client.post(events_url, {"kind": "call"})
        client.post(events_url, {"kind": "whatsapp"})
        client.post(events_url, {"kind": "whatsapp"})
        client.post(events_url, {"kind": "share"})  # not a contact channel — excluded

        response = client.get(reverse("my-listings-stats"), {"days": 7})
        assert response.status_code == 200
        by_channel = response.data["totals"]["by_channel"]
        assert by_channel == {"call": 1, "whatsapp": 2, "message": 0}


@pytest.mark.django_db
class TestAdminAnalytics:
    def test_kpis_require_admin(self):
        client = APIClient()
        assert client.get(reverse("admin-kpis")).status_code == 401

    def test_kpis_count_published_listings(self):
        admin = UserFactory(role="admin")
        ListingFactory(status=ListingStatus.PUBLISHED)
        ListingFactory(status=ListingStatus.PUBLISHED, purpose="rent")
        ListingFactory(status=ListingStatus.DRAFT)

        client = APIClient()
        client.force_authenticate(admin)
        response = client.get(reverse("admin-kpis"))
        assert response.status_code == 200
        assert response.data["total_listings"]["total"] == 2
        assert response.data["for_sale"]["total"] == 1
        assert response.data["for_rent"]["total"] == 1
