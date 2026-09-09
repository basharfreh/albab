from celery import shared_task

from apps.billing.services import expire_promotions


@shared_task
def expire_promotions_task() -> int:
    return expire_promotions()
