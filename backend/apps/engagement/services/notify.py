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
