from django.core.management.base import BaseCommand

from apps.billing.services import expire_promotions


class Command(BaseCommand):
    help = "Expires promotions past their end date and un-features their listings."

    def handle(self, *args, **options):
        count = expire_promotions()
        self.stdout.write(self.style.SUCCESS(f"Expired {count} promotion(s)."))
