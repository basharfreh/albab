import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory
from apps.engagement.models import Notification
from apps.moderation.models import ListingReport, ModerationAction


@pytest.mark.django_db
class TestModerationQueue:
    def test_admin_can_list_pending_queue(self):
        admin = UserFactory(role="admin")
        ListingFactory(status=ListingStatus.PENDING)
        ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(admin)
        response = client.get(reverse("admin-listings"), {"status": "pending"})
        assert response.status_code == 200
        assert response.data["count"] == 1

    def test_non_admin_cannot_access_queue(self):
        seeker = UserFactory(role="seeker")
        client = APIClient()
        client.force_authenticate(seeker)
        assert client.get(reverse("admin-listings")).status_code == 403

    def test_approve_publishes_and_notifies_and_is_discoverable(self):
        admin = UserFactory(role="admin")
        listing = ListingFactory(status=ListingStatus.PENDING)
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(reverse("admin-listing-approve", args=[listing.id]))
        assert response.status_code == 200

        listing.refresh_from_db()
        assert listing.status == ListingStatus.PUBLISHED
        assert listing.published_at is not None
        assert ModerationAction.objects.filter(listing=listing, action="approve").exists()
        assert Notification.objects.filter(user=listing.owner, kind="listing_approved").exists()

        anon = APIClient()
        listing_ids = [row["id"] for row in anon.get(reverse("listing-list")).data["results"]]
        assert listing.id in listing_ids

    def test_reject_requires_reason_and_notifies(self):
        admin = UserFactory(role="admin")
        listing = ListingFactory(status=ListingStatus.PENDING)
        client = APIClient()
        client.force_authenticate(admin)

        missing_reason = client.post(reverse("admin-listing-reject", args=[listing.id]))
        assert missing_reason.status_code == 400

        response = client.post(
            reverse("admin-listing-reject", args=[listing.id]), {"reason": "صور غير واضحة"}
        )
        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == ListingStatus.REJECTED
        assert listing.rejection_reason == "صور غير واضحة"
        assert Notification.objects.filter(user=listing.owner, kind="listing_rejected").exists()

    def test_cannot_approve_non_pending_listing(self):
        admin = UserFactory(role="admin")
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        client.force_authenticate(admin)
        response = client.post(reverse("admin-listing-approve", args=[listing.id]))
        assert response.status_code == 400


@pytest.mark.django_db
class TestReports:
    def test_authenticated_user_can_report_a_listing(self):
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        reporter = UserFactory(role="seeker")
        client = APIClient()
        client.force_authenticate(reporter)
        response = client.post(
            reverse("listing-report", args=[listing.id]), {"reason": "محتوى مضلل"}
        )
        assert response.status_code == 201
        assert ListingReport.objects.filter(listing=listing, reporter=reporter).exists()

    def test_admin_can_close_a_report(self):
        listing = ListingFactory(status=ListingStatus.PUBLISHED)
        report = ListingReport.objects.create(
            listing=listing, reporter=UserFactory(), reason="محتوى مضلل"
        )
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)
        response = client.post(reverse("admin-report-close", args=[report.id]))
        assert response.status_code == 200
        report.refresh_from_db()
        assert report.status == "closed"
        assert report.handled_by == admin
