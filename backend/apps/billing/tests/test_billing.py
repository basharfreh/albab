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

    def test_admin_can_filter_promotions_by_status(self):
        listing = ListingFactory()
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        pending = Promotion.objects.create(listing=listing, package=package)
        active = Promotion.objects.create(
            listing=ListingFactory(), package=package, status=PromotionStatus.ACTIVE
        )
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.get(reverse("admin-promotions"), {"status": "pending"})
        assert response.status_code == 200
        ids = [row["id"] for row in response.data["results"]]
        assert ids == [pending.id]
        assert active.id not in ids

    def test_promotion_serializer_exposes_listing_owner_for_the_payment_dialog(self):
        listing = ListingFactory()
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        Promotion.objects.create(listing=listing, package=package)
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.get(reverse("admin-promotions"))
        row = response.data["results"][0]
        assert row["listing_owner"] == listing.owner_id
        assert row["listing_owner_name"] == listing.owner.name

    def test_admin_can_filter_transactions_by_status_and_date(self):
        listing = ListingFactory()
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        promotion = Promotion.objects.create(listing=listing, package=package)
        admin = UserFactory(role="admin")
        record_transaction(
            user=listing.owner,
            promotion=promotion,
            amount="10.00",
            method="cash",
            recorded_by=admin,
            status="pending",
        )
        client = APIClient()
        client.force_authenticate(admin)

        response = client.get(reverse("admin-transactions"), {"status": "pending"})
        assert response.status_code == 200
        assert response.data["count"] == 1

        response = client.get(reverse("admin-transactions"), {"status": "completed"})
        assert response.data["count"] == 0

        future = (timezone.now() + timezone.timedelta(days=1)).isoformat()
        response = client.get(reverse("admin-transactions"), {"created_at__gte": future})
        assert response.data["count"] == 0

    def test_transaction_serializer_exposes_user_and_listing_names(self):
        listing = ListingFactory()
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        promotion = Promotion.objects.create(listing=listing, package=package)
        admin = UserFactory(role="admin")
        record_transaction(
            user=listing.owner,
            promotion=promotion,
            amount="10.00",
            method="cash",
            recorded_by=admin,
        )
        client = APIClient()
        client.force_authenticate(admin)

        response = client.get(reverse("admin-transactions"))
        row = response.data["results"][0]
        assert row["user_name"] == listing.owner.name
        assert row["listing_title"] == listing.title


@pytest.mark.django_db
class TestAdminPromotionPackages:
    def test_non_admin_cannot_list(self):
        client = APIClient()
        client.force_authenticate(UserFactory(role="seeker"))
        assert client.get(reverse("admin-promotion-package-list")).status_code == 403

    def test_admin_can_create_update_and_deactivate(self):
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        create_response = client.post(
            reverse("admin-promotion-package-list"),
            {"name_ar": "أسبوعان", "name_en": "Two weeks", "days": 14, "price": "18.00"},
        )
        assert create_response.status_code == 201
        package_id = create_response.data["id"]

        update_response = client.patch(
            reverse("admin-promotion-package-detail", args=[package_id]),
            {"is_active": False},
        )
        assert update_response.status_code == 200
        assert update_response.data["is_active"] is False

    def test_deleting_a_package_in_use_is_rejected_not_500(self):
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        Promotion.objects.create(listing=ListingFactory(), package=package)
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.delete(reverse("admin-promotion-package-detail", args=[package.id]))
        assert response.status_code == 400
        assert PromotionPackage.objects.filter(pk=package.id).exists()

    def test_deleting_an_unused_package_succeeds(self):
        package = PromotionPackage.objects.create(name_ar="أسبوع", days=7, price="10.00")
        admin = UserFactory(role="admin")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.delete(reverse("admin-promotion-package-detail", args=[package.id]))
        assert response.status_code == 204
        assert not PromotionPackage.objects.filter(pk=package.id).exists()
