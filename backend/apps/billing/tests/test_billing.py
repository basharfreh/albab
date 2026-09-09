import pytest
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.billing.models import Promotion, PromotionPackage, PromotionStatus
from apps.billing.services import expire_promotions, record_transaction
from apps.catalog.tests.factories import ListingFactory


@pytest.mark.django_db
class TestPromotionsAndTransactions:
    def test_completed_transaction_activates_promotion_and_features_listing(self):
        listing = ListingFactory()
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        promotion = Promotion.objects.create(listing=listing, package=package)
        owner = listing.owner
        admin = UserFactory(role="admin")

        record_transaction(
            user=owner,
            promotion=promotion,
            amount="10.00",
            method="cash",
            recorded_by=admin,
        )

        promotion.refresh_from_db()
        listing.refresh_from_db()
        assert promotion.status == PromotionStatus.ACTIVE
        assert listing.is_featured is True
        assert listing.featured_until is not None

    def test_pending_transaction_does_not_activate(self):
        listing = ListingFactory()
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        promotion = Promotion.objects.create(listing=listing, package=package)

        record_transaction(
            user=listing.owner,
            promotion=promotion,
            amount="10.00",
            method="cash",
            recorded_by=UserFactory(role="admin"),
            status="pending",
        )

        promotion.refresh_from_db()
        assert promotion.status == PromotionStatus.PENDING

    def test_expire_promotions_unfeatures_listing(self):
        listing = ListingFactory(is_featured=True)
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        promotion = Promotion.objects.create(
            listing=listing,
            package=package,
            status=PromotionStatus.ACTIVE,
            starts_at=timezone.now() - timezone.timedelta(days=10),
            ends_at=timezone.now() - timezone.timedelta(days=3),
        )

        count = expire_promotions()

        promotion.refresh_from_db()
        listing.refresh_from_db()
        assert count == 1
        assert promotion.status == PromotionStatus.EXPIRED
        assert listing.is_featured is False

    def test_non_admin_cannot_record_transaction(self):
        seeker = UserFactory(role="seeker")
        client = APIClient()
        client.force_authenticate(seeker)
        response = client.get(reverse("admin-transactions"))
        assert response.status_code == 403
