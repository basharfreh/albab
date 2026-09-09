from django.utils import timezone

from apps.billing.models import Promotion, PromotionStatus, Transaction


def activate_promotion(promotion: Promotion) -> None:
    now = timezone.now()
    ends_at = now + timezone.timedelta(days=promotion.package.days)
    promotion.starts_at = now
    promotion.ends_at = ends_at
    promotion.status = PromotionStatus.ACTIVE
    promotion.save(update_fields=["starts_at", "ends_at", "status"])

    listing = promotion.listing
    listing.is_featured = True
    listing.featured_until = ends_at
    listing.save(update_fields=["is_featured", "featured_until", "updated_at"])


def record_transaction(
    *,
    user,
    promotion: Promotion,
    amount,
    method,
    recorded_by,
    currency="USD",
    reference="",
    status="completed",
) -> Transaction:
    """Records a manually-entered payment. A "completed" transaction activates the promotion."""
    transaction = Transaction.objects.create(
        user=user,
        promotion=promotion,
        amount=amount,
        currency=currency,
        method=method,
        reference=reference,
        status=status,
        recorded_by=recorded_by,
    )
    if transaction.status == "completed":
        activate_promotion(promotion)
    return transaction


def expire_promotions() -> int:
    """Hourly job (Celery beat + a plain management command): expire lapsed promotions."""
    now = timezone.now()
    expired = Promotion.objects.filter(status=PromotionStatus.ACTIVE, ends_at__lt=now)
    count = 0
    for promotion in expired.select_related("listing"):
        promotion.status = PromotionStatus.EXPIRED
        promotion.save(update_fields=["status"])
        listing = promotion.listing
        listing.is_featured = False
        listing.featured_until = None
        listing.save(update_fields=["is_featured", "featured_until", "updated_at"])
        count += 1
    return count
