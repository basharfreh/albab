from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.catalog.models import ListingStatus
from apps.engagement.services.notify import notify_listing_approved, notify_listing_rejected
from apps.moderation.models import ListingReport, ModerationAction, ModerationActionType


def approve_listing(*, listing, admin) -> None:
    if listing.status != ListingStatus.PENDING:
        raise ValidationError("لا يمكن الموافقة على عقار ليس قيد المراجعة.")

    listing.status = ListingStatus.PUBLISHED
    listing.published_at = timezone.now()
    listing.save(update_fields=["status", "published_at", "updated_at"])

    ModerationAction.objects.create(
        listing=listing, admin=admin, action=ModerationActionType.APPROVE
    )
    notify_listing_approved(listing)


def reject_listing(*, listing, admin, reason: str) -> None:
    if not reason:
        raise ValidationError({"reason": ["سبب الرفض مطلوب."]})
    if listing.status != ListingStatus.PENDING:
        raise ValidationError("لا يمكن رفض عقار ليس قيد المراجعة.")

    listing.status = ListingStatus.REJECTED
    listing.rejection_reason = reason
    listing.save(update_fields=["status", "rejection_reason", "updated_at"])

    ModerationAction.objects.create(
        listing=listing, admin=admin, action=ModerationActionType.REJECT, reason=reason
    )
    notify_listing_rejected(listing)


def report_listing(*, listing, reporter, reason: str, note: str = "") -> ListingReport:
    return ListingReport.objects.create(
        listing=listing, reporter=reporter, reason=reason, note=note
    )


def close_report(*, report: ListingReport, admin) -> None:
    from apps.moderation.models import ReportStatus

    report.status = ReportStatus.CLOSED
    report.handled_by = admin
    report.save(update_fields=["status", "handled_by"])
