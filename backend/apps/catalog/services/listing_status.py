from rest_framework.exceptions import ValidationError

from apps.catalog.models import ListingStatus

# Owner-initiated transitions only, via POST /listings/{id}/status/.
# pending is reached only through submit(); published/rejected only through admin
# moderation (P3). Anything not listed here has no legal owner-initiated transition.
ALLOWED_TRANSITIONS = {
    ListingStatus.PUBLISHED: {ListingStatus.SOLD, ListingStatus.RENTED, ListingStatus.PAUSED},
    ListingStatus.PAUSED: {ListingStatus.PUBLISHED},
}


def transition_status(listing, target_status: str) -> None:
    allowed = ALLOWED_TRANSITIONS.get(listing.status, set())
    if target_status not in allowed:
        raise ValidationError(
            f"لا يمكن تغيير حالة العقار من {listing.get_status_display()} إلى هذه الحالة."
        )
    listing.status = target_status
    listing.save(update_fields=["status", "updated_at"])
