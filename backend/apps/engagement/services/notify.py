from apps.engagement.models import Notification, NotificationKind
from apps.engagement.services.push import get_push_backend


def notify(
    *, user, kind: str, title: str, body: str = "", data: dict | None = None
) -> Notification:
    """Single place notifications are created. Push delivery is a no-op for now."""
    notification = Notification.objects.create(
        user=user, kind=kind, title=title, body=body, data=data or {}
    )
    get_push_backend().send(notification)
    return notification


def notify_listing_approved(listing) -> Notification:
    return notify(
        user=listing.owner,
        kind=NotificationKind.LISTING_APPROVED,
        title="تمت الموافقة على عقارك",
        body=f'تمت الموافقة على "{listing.title}" وهو الآن منشور.',
        data={"listing_id": listing.id},
    )


def notify_listing_rejected(listing) -> Notification:
    return notify(
        user=listing.owner,
        kind=NotificationKind.LISTING_REJECTED,
        title="تم رفض عقارك",
        body=listing.rejection_reason or f'تم رفض "{listing.title}".',
        data={"listing_id": listing.id},
    )


def notify_new_message(message) -> Notification:
    conversation = message.conversation
    recipient = (
        conversation.owner if message.sender_id == conversation.seeker_id else conversation.seeker
    )
    return notify(
        user=recipient,
        kind=NotificationKind.NEW_MESSAGE,
        title="رسالة جديدة",
        body=message.body[:200],
        data={"conversation_id": conversation.id, "listing_id": conversation.listing_id},
    )


def notify_promotion_expiring(promotion) -> Notification:
    return notify(
        user=promotion.listing.owner,
        kind=NotificationKind.PROMOTION_EXPIRING,
        title="إعلانك على وشك الانتهاء",
        body=f'تمييز "{promotion.listing.title}" ينتهي قريباً.',
        data={"listing_id": promotion.listing_id, "promotion_id": promotion.id},
    )


def broadcast_notification(
    *, title: str, body: str = "", target: str, role: str | None = None, user=None
) -> int:
    """UC-3: الإشعارات' broadcast composer — `target` is `all`/`role`/`user`. Returns how many
    notifications were created (the dashboard shows this as confirmation). Uses `bulk_create`
    since `target=all` can mean every user on the platform, not just one; `get_push_backend()`
    is still called once per notification — a no-op today (`NoOpPushBackend`), so this doesn't
    cost anything real yet, but a future real backend would want a proper bulk-send API rather
    than N calls here."""
    from apps.accounts.models import User

    if target == "user":
        users = User.objects.filter(pk=user.pk) if user else User.objects.none()
    elif target == "role":
        users = User.objects.filter(role=role)
    else:
        users = User.objects.all()

    notifications = [
        Notification(user=recipient, kind=NotificationKind.BROADCAST, title=title, body=body)
        for recipient in users
    ]
    Notification.objects.bulk_create(notifications)

    backend = get_push_backend()
    for notification in notifications:
        backend.send(notification)
    return len(notifications)
