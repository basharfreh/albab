from django.db import models
from django.utils import timezone

from apps.accounts.models import User
from apps.analytics.models import ListingDailyStat, ListingEvent, ListingEventKind
from apps.catalog.models import Listing, ListingPurpose, ListingStatus

# The three event kinds that count as a "contact" (brief §4 rule 2 / P3's own framing —
# `share` is logged but never counted as a contact). Split out here so `totals.by_channel`
# in `owner_listing_stats` names exactly the channels P10's stats screen needs, without
# adding a new field to `ListingDailyStat` (which only ever tracked one combined "contacts"
# number — brief §6 doesn't give it a per-kind breakdown, so this queries `ListingEvent`
# directly instead of extending that model).
CONTACT_EVENT_KINDS = (ListingEventKind.CALL, ListingEventKind.WHATSAPP, ListingEventKind.MESSAGE)


def owner_listing_stats(user, days: int = 30) -> dict:
    """Per-day views/contacts series (summed across the owner's listings) plus totals."""
    since = timezone.now().date() - timezone.timedelta(days=days - 1)
    stats = ListingDailyStat.objects.filter(listing__owner=user, date__gte=since)

    by_date: dict = {}
    for stat in stats:
        entry = by_date.setdefault(stat.date, {"views": 0, "contacts": 0})
        entry["views"] += stat.views
        entry["contacts"] += stat.contacts

    series = [
        {
            "date": since + timezone.timedelta(days=offset),
            **by_date.get(since + timezone.timedelta(days=offset), {"views": 0, "contacts": 0}),
        }
        for offset in range(days)
    ]

    since_dt = timezone.make_aware(timezone.datetime.combine(since, timezone.datetime.min.time()))
    channel_events = ListingEvent.objects.filter(
        listing__owner=user, kind__in=CONTACT_EVENT_KINDS, created_at__gte=since_dt
    )
    by_channel = {kind.value: 0 for kind in CONTACT_EVENT_KINDS}
    for row in channel_events.values("kind").annotate(total=models.Count("id")):
        by_channel[row["kind"]] = row["total"]

    totals = {
        "views": sum(day["views"] for day in series),
        "contacts": sum(day["contacts"] for day in series),
        "by_channel": by_channel,
    }
    return {"series": series, "totals": totals}


def _with_30d_delta(queryset) -> dict:
    since = timezone.now() - timezone.timedelta(days=30)
    total = queryset.count()
    delta = queryset.filter(created_at__gte=since).count()
    return {"total": total, "delta_30d": delta}


def admin_kpis() -> dict:
    """UC-50: total users, total listings, for-sale, for-rent — each with a 30-day delta.

    The delta is "how many of these were created in the last 30 days" (net new), since we
    don't keep historical snapshots to diff against.
    """
    published = Listing.objects.filter(status=ListingStatus.PUBLISHED)
    return {
        "total_users": _with_30d_delta(User.objects.all()),
        "total_listings": _with_30d_delta(published),
        "for_sale": _with_30d_delta(published.filter(purpose=ListingPurpose.SALE)),
        "for_rent": _with_30d_delta(published.filter(purpose=ListingPurpose.RENT)),
    }


def admin_visits_series(days: int = 30) -> list[dict]:
    """UC-51: platform-wide views/contacts per day, last `days` days."""
    since = timezone.now().date() - timezone.timedelta(days=days - 1)
    stats = ListingDailyStat.objects.filter(date__gte=since)

    by_date: dict = {}
    for stat in stats:
        entry = by_date.setdefault(stat.date, {"views": 0, "contacts": 0})
        entry["views"] += stat.views
        entry["contacts"] += stat.contacts

    return [
        {
            "date": since + timezone.timedelta(days=offset),
            **by_date.get(since + timezone.timedelta(days=offset), {"views": 0, "contacts": 0}),
        }
        for offset in range(days)
    ]


def admin_by_type_breakdown() -> list[dict]:
    """UC-52: published listing counts by property_type, for the admin pie chart."""
    from django.db.models import Count

    rows = (
        Listing.objects.filter(status=ListingStatus.PUBLISHED)
        .values("property_type")
        .annotate(count=Count("id"))
        .order_by("-count")
    )
    return list(rows)
