from rest_framework.exceptions import ValidationError

from apps.catalog.models import Listing, ListingStatus

ACTIVE_STATUSES = [ListingStatus.PENDING, ListingStatus.PUBLISHED, ListingStatus.PAUSED]

QUOTAS = {
    "seeker": 0,
    "owner": 10,
    "agency": 100,
}


def check_quota(user) -> None:
    quota = QUOTAS.get(user.role, 0)
    active_count = Listing.objects.filter(owner=user, status__in=ACTIVE_STATUSES).count()
    if active_count >= quota:
        raise ValidationError(
            f"لقد وصلت إلى الحد الأقصى لعدد العقارات النشطة ({quota}). "
            "قم بإلغاء نشر عقار آخر أو الترقية للحصول على حصة أكبر."
        )
