import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.catalog.models import ListingStatus
from apps.catalog.tests.factories import ListingFactory, NeighborhoodFactory


@pytest.mark.django_db
class TestResponseCaching:
    def test_neighborhoods_response_is_cached_for_60s(self):
        NeighborhoodFactory()
        client = APIClient()
        first = client.get(reverse("neighborhoods"))
        assert len(first.data) == 1

        NeighborhoodFactory()  # a second one shouldn't show up while the first response is cached
        second = client.get(reverse("neighborhoods"))
        assert len(second.data) == 1

    def test_map_response_is_cached_for_60s(self):
        ListingFactory(status=ListingStatus.PUBLISHED)
        client = APIClient()
        first = client.get(reverse("listing-map"))
        assert first.data["results"] and len(first.data["results"]) == 1

        ListingFactory(status=ListingStatus.PUBLISHED)
        second = client.get(reverse("listing-map"))
        assert len(second.data["results"]) == 1
