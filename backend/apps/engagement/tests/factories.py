import factory

from apps.accounts.tests.factories import UserFactory
from apps.catalog.tests.factories import ListingFactory
from apps.engagement.models import Conversation


class ConversationFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Conversation

    listing = factory.SubFactory(ListingFactory)
    seeker = factory.SubFactory(UserFactory, role="seeker")

    @factory.lazy_attribute
    def owner(self):
        return self.listing.owner
