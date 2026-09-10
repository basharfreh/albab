from django.conf import settings
from django.db import models

from apps.common.models import TimeStampedModel


class PropertyType(models.TextChoices):
    HOUSE = "house", "منزل"
    APARTMENT = "apartment", "شقة"
    SHOP = "shop", "محل"
    LAND = "land", "أرض"
    OTHER = "other", "أخرى"


class ListingPurpose(models.TextChoices):
    SALE = "sale", "للبيع"
    RENT = "rent", "للإيجار"


class ListingStatus(models.TextChoices):
    DRAFT = "draft", "مسودة"
    PENDING = "pending", "قيد المراجعة"
    PUBLISHED = "published", "منشور"
    REJECTED = "rejected", "مرفوض"
    SOLD = "sold", "مباع"
    RENTED = "rented", "مؤجر"
    PAUSED = "paused", "معلق"


class Neighborhood(models.Model):
    name_ar = models.CharField(max_length=100)
    name_en = models.CharField(max_length=100, blank=True)
    slug = models.SlugField(unique=True)
    center_lat = models.DecimalField(max_digits=9, decimal_places=6)
    center_lng = models.DecimalField(max_digits=9, decimal_places=6)
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "name_ar"]

    def __str__(self):
        return self.name_ar


class ListingQuotaSettings(models.Model):
    """Singleton (always `pk=1`, see `get_solo`) — UC-59's admin-editable quotas, read by
    `services/quota.py` instead of the hardcoded constants P2 originally shipped."""

    seeker = models.PositiveIntegerField(default=0)
    owner = models.PositiveIntegerField(default=10)
    agency = models.PositiveIntegerField(default=100)

    class Meta:
        verbose_name = "Listing quota settings"
        verbose_name_plural = "Listing quota settings"

    def __str__(self):
        return "Listing quotas"

    @classmethod
    def get_solo(cls) -> "ListingQuotaSettings":
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


class Listing(TimeStampedModel):
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="listings"
    )
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    property_type = models.CharField(max_length=10, choices=PropertyType.choices)
    purpose = models.CharField(max_length=5, choices=ListingPurpose.choices)
    price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    currency = models.CharField(max_length=3, default="USD")
    is_negotiable = models.BooleanField(default=False)
    area_sqm = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    bedrooms = models.PositiveSmallIntegerField(null=True, blank=True)
    bathrooms = models.PositiveSmallIntegerField(null=True, blank=True)
    neighborhood = models.ForeignKey(
        Neighborhood, on_delete=models.PROTECT, null=True, blank=True, related_name="listings"
    )
    landmark = models.CharField(max_length=200, blank=True)
    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    status = models.CharField(
        max_length=10, choices=ListingStatus.choices, default=ListingStatus.DRAFT
    )
    rejection_reason = models.CharField(max_length=500, blank=True)
    views_count = models.PositiveIntegerField(default=0)
    contacts_count = models.PositiveIntegerField(default=0)
    is_featured = models.BooleanField(default=False)
    featured_until = models.DateTimeField(null=True, blank=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-is_featured", "-published_at"]
        indexes = [
            models.Index(fields=["status", "published_at"]),
            models.Index(fields=["lat", "lng"]),
            models.Index(fields=["purpose", "property_type"]),
            models.Index(fields=["neighborhood", "status"]),
        ]

    def __str__(self):
        return self.title


class ListingImage(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="images")
    image = models.ImageField(upload_to="listings/")
    thumbnail = models.ImageField(upload_to="listings/thumbnails/", blank=True, null=True)
    sort_order = models.PositiveSmallIntegerField(default=0)
    is_cover = models.BooleanField(default=False)

    class Meta:
        ordering = ["sort_order", "id"]

    def __str__(self):
        return f"Image({self.listing_id}, #{self.sort_order})"


class Favorite(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="favorites"
    )
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="favorited_by")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("user", "listing")]
        ordering = ["-created_at"]
