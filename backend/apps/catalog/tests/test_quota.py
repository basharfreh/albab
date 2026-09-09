import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory, NeighborhoodFactory


def _make_submittable_draft(owner):
    neighborhood = NeighborhoodFactory()
    listing = ListingFactory(
        owner=owner,
        status=ListingStatus.DRAFT,
        neighborhood=neighborhood,
        price="10000.00",
        lat="36.370000",
        lng="37.517000",
    )
    listing.images.create(image="placeholder.jpg")
    return listing


@pytest.mark.django_db
class TestQuota:
    def test_seeker_cannot_submit_any_listing(self):
        seeker = UserFactory(role="seeker")
        listing = _make_submittable_draft(seeker)
        client = APIClient()
        client.force_authenticate(seeker)
        response = client.post(reverse("listing-submit", args=[listing.id]))
        assert response.status_code == 400

    def test_owner_quota_of_ten_active_listings_enforced(self):
        owner = UserFactory(role="owner")
        for _ in range(10):
            ListingFactory(owner=owner, status=ListingStatus.PUBLISHED)
        listing = _make_submittable_draft(owner)

        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(reverse("listing-submit", args=[listing.id]))
        assert response.status_code == 400

    def test_owner_under_quota_can_submit(self):
        owner = UserFactory(role="owner")
        listing = _make_submittable_draft(owner)

        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(reverse("listing-submit", args=[listing.id]))
        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == ListingStatus.PENDING

    def test_agency_quota_of_hundred_not_hit_at_ten(self):
        agency = UserFactory(role="agency")
        for _ in range(10):
            ListingFactory(owner=agency, status=ListingStatus.PUBLISHED)
        listing = _make_submittable_draft(agency)

        client = APIClient()
        client.force_authenticate(agency)
        response = client.post(reverse("listing-submit", args=[listing.id]))
        assert response.status_code == 200
