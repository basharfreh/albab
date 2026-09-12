import pytest
from django.db.models import Sum
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.analytics.models import ListingDailyStat, ListingEvent
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

    def test_denormalized_counters_stay_in_sync_with_the_daily_rollup(self):
        """Brief P12 item 6: "owner stats and admin KPIs agree on the same numbers" only
        holds if `Listing.views_count`/`contacts_count` (what the admin's "most viewed" sort
        and the mobile "my listings" row count read) and `ListingDailyStat` (what both the
        owner stats screen and the admin visits chart sum) never drift apart — `record_event`
        writes to all three in one `transaction.atomic()` block specifically so this holds
        even if a request gets interrupted mid-write.
        """
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        url = reverse("listing-events", args=[listing.id])

        # Two different IPs so neither `view` gets throttled (P3's "once per hour per IP").
        client.post(url, {"kind": "view"}, REMOTE_ADDR="10.0.0.1")
        client.post(url, {"kind": "view"}, REMOTE_ADDR="10.0.0.2")
        client.post(url, {"kind": "call"})
        client.post(url, {"kind": "whatsapp"})
        client.post(url, {"kind": "whatsapp"})

        listing.refresh_from_db()
        daily_totals = ListingDailyStat.objects.filter(listing=listing).aggregate(
            views=Sum("views"), contacts=Sum("contacts")
        )
        assert listing.views_count == daily_totals["views"] == 2
        assert listing.contacts_count == daily_totals["contacts"] == 3


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

    def test_owner_totals_and_the_admin_visits_series_agree_on_the_same_numbers(self):
        """Brief P12 item 6, checked end to end through both real endpoints rather than just
        the shared model layer: with exactly one listing/owner in the whole test database,
        the owner's own 7-day totals and the platform-wide admin visits series must sum to
        the same numbers — there's nothing else in the system that could make them diverge.
        """
        owner = UserFactory(role="owner")
        admin = UserFactory(role="admin")
        listing = ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        client = APIClient()
        events_url = reverse("listing-events", args=[listing.id])
        client.post(events_url, {"kind": "view"}, REMOTE_ADDR="10.0.0.1")
        client.post(events_url, {"kind": "view"}, REMOTE_ADDR="10.0.0.2")
        client.post(events_url, {"kind": "call"})

        client.force_authenticate(owner)
        owner_totals = client.get(reverse("my-listings-stats"), {"days": 7}).data["totals"]

        client.force_authenticate(admin)
        admin_series = client.get(reverse("admin-visits"), {"days": 7}).data
        admin_totals = {
            "views": sum(day["views"] for day in admin_series),
            "contacts": sum(day["contacts"] for day in admin_series),
        }

        assert owner_totals["views"] == admin_totals["views"] == 2
        assert owner_totals["contacts"] == admin_totals["contacts"] == 1


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
