import factory
from django.utils import timezone

from apps.accounts.tests.factories import UserFactory
from apps.catalog.models import Listing, ListingPurpose, ListingStatus, Neighborhood, PropertyType


class NeighborhoodFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Neighborhood
        django_get_or_create = ("slug",)

    name_ar = factory.Sequence(lambda n: f"حي {n}")
    name_en = factory.Sequence(lambda n: f"District {n}")
    slug = factory.Sequence(lambda n: f"district-{n}")
    center_lat = "36.372000"
    center_lng = "37.517000"


class ListingFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Listing

    owner = factory.SubFactory(UserFactory, role="owner")
    title = factory.Sequence(lambda n: f"عقار رقم {n}")
    property_type = PropertyType.APARTMENT
    purpose = ListingPurpose.SALE
    price = "100000.00"
    area_sqm = "120.00"
    bedrooms = 3
    bathrooms = 2
    neighborhood = factory.SubFactory(NeighborhoodFactory)
    landmark = "قرب جامع النور"
    lat = "36.372000"
    lng = "37.517000"
    status = ListingStatus.PUBLISHED
    published_at = factory.LazyFunction(timezone.now)
