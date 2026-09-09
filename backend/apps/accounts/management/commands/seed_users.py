from django.core.management.base import BaseCommand

from apps.accounts.models import User, UserRole

DEMO_USERS = [
    {
        "phone": "+963900000001",
        "name": "مشرف الباب",
        "role": UserRole.ADMIN,
        "password": "Admin12345",
        "is_staff": True,
        "is_superuser": True,
    },
    {
        "phone": "+963900000002",
        "name": "مكتب الشام العقاري",
        "role": UserRole.AGENCY,
        "password": "Agency12345",
        "agency_name": "مكتب الشام العقاري",
    },
    {
        "phone": "+963900000003",
        "name": "أحمد العلي",
        "role": UserRole.OWNER,
        "password": "Owner12345",
    },
    {
        "phone": "+963900000004",
        "name": "محمد الحسن",
        "role": UserRole.OWNER,
        "password": "Owner12345",
    },
    {
        "phone": "+963900000005",
        "name": "سارة أحمد",
        "role": UserRole.SEEKER,
        "password": "Seeker12345",
    },
    {
        "phone": "+963900000006",
        "name": "ليلى محمود",
        "role": UserRole.SEEKER,
        "password": "Seeker12345",
    },
]


class Command(BaseCommand):
    help = "Seed demo users: one admin, one agency, two owners, two seekers."

    def handle(self, *args, **options):
        created = 0
        for data in DEMO_USERS:
            data = dict(data)
            phone = data.pop("phone")
            password = data.pop("password")
            if User.objects.filter(phone=phone).exists():
                continue
            User.objects.create_user(phone=phone, password=password, is_phone_verified=True, **data)
            created += 1
        self.stdout.write(self.style.SUCCESS(f"Seeded {created} user(s)."))
