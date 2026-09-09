import hashlib

from django.conf import settings
from django.db.models import F
from django.utils import timezone

from apps.analytics.models import ListingDailyStat, ListingEvent, ListingEventKind

CONTACT_KINDS = {ListingEventKind.CALL, ListingEventKind.WHATSAPP, ListingEventKind.MESSAGE}
VIEW_THROTTLE_WINDOW_HOURS = 1


def compute_ip_hash(request) -> str:
    ip = request.META.get("REMOTE_ADDR", "")
    salted = f"{settings.SECRET_KEY}:{ip}"
    return hashlib.sha256(salted.encode()).hexdigest()


def record_event(
    *, listing, kind: str, user=None, ip_hash: str | None = None
) -> ListingEvent | None:
    """Logs a ListingEvent and rolls it into daily/denormalised counters.

    Views are throttled to one per listing per ip_hash per hour (returns None, no-op,
    on a throttled repeat). Call/whatsapp/message count as contacts; share is logged only.
    """
    now = timezone.now()

    if kind == ListingEventKind.VIEW and ip_hash:
        window_start = now - timezone.timedelta(hours=VIEW_THROTTLE_WINDOW_HOURS)
        already_seen = ListingEvent.objects.filter(
            listing=listing, kind=kind, ip_hash=ip_hash, created_at__gte=window_start
        ).exists()
        if already_seen:
            return None

    event = ListingEvent.objects.create(
        listing=listing, kind=kind, user=user, ip_hash=ip_hash or ""
    )

    stat, _ = ListingDailyStat.objects.get_or_create(listing=listing, date=now.date())
    if kind == ListingEventKind.VIEW:
        listing.__class__.objects.filter(pk=listing.pk).update(views_count=F("views_count") + 1)
        ListingDailyStat.objects.filter(pk=stat.pk).update(views=F("views") + 1)
    elif kind in CONTACT_KINDS:
        listing.__class__.objects.filter(pk=listing.pk).update(
            contacts_count=F("contacts_count") + 1
        )
        ListingDailyStat.objects.filter(pk=stat.pk).update(contacts=F("contacts") + 1)

    return event
