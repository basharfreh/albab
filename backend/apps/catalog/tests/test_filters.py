import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.catalog.models import ListingPurpose, ListingStatus
from apps.catalog.tests.factories import ListingFactory, NeighborhoodFactory


@pytest.mark.django_db
class TestListingFilters:
    def test_purpose_price_bedrooms_and_bbox_combine(self):
        ListingFactory(
            purpose=ListingPurpose.SALE,
            price="60000.00",
            bedrooms=3,
            lat="36.372000",
            lng="37.517000",
        )
        ListingFactory(purpose=ListingPurpose.RENT, price="500.00", bedrooms=1)
        ListingFactory(purpose=ListingPurpose.SALE, price="40000.00", bedrooms=2)

        client = APIClient()
        response = client.get(
            reverse("listing-list"),
            {
                "purpose": "sale",
                "min_price": "50000",
                "bedrooms": "3+",
                "bbox": "37.400,36.300,37.600,36.450",
            },
        )
        assert response.status_code == 200
        assert response.data["count"] == 1

    def test_bedrooms_exact_vs_at_least(self):
        ListingFactory(bedrooms=2)
        ListingFactory(bedrooms=3)
        ListingFactory(bedrooms=4)

        client = APIClient()
        exact = client.get(reverse("listing-list"), {"bedrooms": "3"})
        at_least = client.get(reverse("listing-list"), {"bedrooms": "3+"})
        assert exact.data["count"] == 1
        assert at_least.data["count"] == 2

    def test_q_searches_title_and_neighborhood_name(self):
        neighborhood = NeighborhoodFactory(name_ar="حي التجارب")
        ListingFactory(title="شقة عادية", neighborhood=neighborhood)
        ListingFactory(title="محل تجاري")

        client = APIClient()
        response = client.get(reverse("listing-list"), {"q": "التجارب"})
        assert response.status_code == 200
        assert response.data["count"] == 1

    def test_draft_and_pending_excluded_from_public_list(self):
        ListingFactory(status=ListingStatus.DRAFT)
        ListingFactory(status=ListingStatus.PENDING)
        ListingFactory(status=ListingStatus.PUBLISHED)

        client = APIClient()
        response = client.get(reverse("listing-list"))
        assert response.data["count"] == 1

    def test_map_endpoint_returns_markers_for_bbox(self):
        ListingFactory(lat="36.372000", lng="37.517000")
        ListingFactory(lat="10.000000", lng="10.000000")  # outside the bbox

        client = APIClient()
        response = client.get(reverse("listing-map"), {"bbox": "37.400,36.300,37.600,36.450"})
        assert response.status_code == 200
        assert response.data["truncated"] is False
        assert len(response.data["results"]) == 1
