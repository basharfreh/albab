import io
import random

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone
from PIL import Image as PILImage

from apps.accounts.models import User
from apps.catalog.models import (
    Listing,
    ListingImage,
    ListingPurpose,
    ListingStatus,
    Neighborhood,
    PropertyType,
)
from apps.catalog.services.images import make_thumbnail

NEIGHBORHOODS = [
    {
        "name_ar": "حي الحسين",
        "name_en": "Al-Hussein",
        "slug": "al-hussein",
        "center_lat": "36.376000",
        "center_lng": "37.515000",
        "sort_order": 1,
    },
    {
        "name_ar": "حي الزهراء",
        "name_en": "Al-Zahraa",
        "slug": "al-zahraa",
        "center_lat": "36.370000",
        "center_lng": "37.523000",
        "sort_order": 2,
    },
    {
        "name_ar": "حي المشلب",
        "name_en": "Al-Mashlab",
        "slug": "al-mashlab",
        "center_lat": "36.366000",
        "center_lng": "37.510000",
        "sort_order": 3,
    },
    {
        "name_ar": "حي الصناعة",
        "name_en": "Al-Sinaa",
        "slug": "al-sinaa",
        "center_lat": "36.380000",
        "center_lng": "37.528000",
        "sort_order": 4,
    },
]

LANDMARKS = [
    "قرب جامع النور",
    "قرب مدرسة الفارابي",
    "قرب السوق الشعبي",
    "قرب المشفى الوطني",
    "قرب دوار الساعة",
    "قرب حديقة الأطفال",
    "قرب محطة الوقود",
    "قرب الفرن الآلي",
]

TITLES = {
    PropertyType.HOUSE: ["منزل عائلي واسع", "منزل مستقل بحديقة", "منزل حديث البناء"],
    PropertyType.APARTMENT: ["شقة مطلة وواسعة", "شقة حديثة التشطيب", "شقة عائلية مريحة"],
    PropertyType.SHOP: ["محل تجاري على الشارع الرئيسي", "محل بموقع مميز", "محل واسع للإيجار"],
    PropertyType.LAND: ["أرض سكنية للبيع", "قطعة أرض مميزة", "أرض بموقع استثماري"],
    PropertyType.OTHER: ["عقار متنوع الاستخدام", "مبنى متعدد الاستخدامات"],
}

PLACEHOLDER_COLORS = [
    (217, 119, 6),
    (27, 139, 76),
    (59, 130, 246),
    (139, 92, 246),
    (225, 75, 75),
]

LISTING_COUNT = 60


def _make_placeholder_image(color, index):
    image = PILImage.new("RGB", (1200, 900), color)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=85)
    buffer.seek(0)
    return ContentFile(buffer.read(), name=f"placeholder_{index}.jpg")


class Command(BaseCommand):
    help = "Seed the four Al-Bab neighborhoods and 60 demo published listings."

    def handle(self, *args, **options):
        neighborhoods = []
        for data in NEIGHBORHOODS:
            neighborhood, _ = Neighborhood.objects.update_or_create(
                slug=data["slug"], defaults=data
            )
            neighborhoods.append(neighborhood)

        owners = list(User.objects.filter(role__in=["owner", "agency"]))
        if not owners:
            raise CommandError("No owner/agency users found. Run `manage.py seed_users` first.")

        property_types = list(PropertyType.values)
        purposes = list(ListingPurpose.values)

        created = 0
        for _ in range(LISTING_COUNT):
            property_type = random.choice(property_types)
            purpose = random.choice(purposes)
            neighborhood = random.choice(neighborhoods)
            owner = random.choice(owners)
            lat = float(neighborhood.center_lat) + random.uniform(-0.006, 0.006)
            lng = float(neighborhood.center_lng) + random.uniform(-0.006, 0.006)
            is_land = property_type == PropertyType.LAND

            listing = Listing.objects.create(
                owner=owner,
                title=random.choice(TITLES[property_type]),
                description="عقار مميز في منطقة هادئة وقريبة من جميع الخدمات.",
                property_type=property_type,
                purpose=purpose,
                price=round(random.uniform(15000, 250000), 2),
                is_negotiable=random.choice([True, False]),
                area_sqm=round(random.uniform(50, 400), 2),
                bedrooms=None if is_land else random.randint(1, 6),
                bathrooms=None if is_land else random.randint(1, 3),
                neighborhood=neighborhood,
                landmark=random.choice(LANDMARKS),
                lat=round(lat, 6),
                lng=round(lng, 6),
                status=ListingStatus.PUBLISHED,
                published_at=timezone.now(),
            )

            for image_index in range(random.randint(1, 3)):
                color = random.choice(PLACEHOLDER_COLORS)
                image_file = _make_placeholder_image(color, image_index)
                thumbnail = make_thumbnail(image_file)
                image_file.seek(0)
                ListingImage.objects.create(
                    listing=listing,
                    image=image_file,
                    thumbnail=thumbnail,
                    sort_order=image_index,
                    is_cover=(image_index == 0),
                )
            created += 1

        self.stdout.write(
            self.style.SUCCESS(f"Seeded {len(neighborhoods)} neighborhoods and {created} listings.")
        )
