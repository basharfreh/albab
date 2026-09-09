from django.contrib import admin

from apps.billing.models import Promotion, PromotionPackage, Transaction


@admin.register(PromotionPackage)
class PromotionPackageAdmin(admin.ModelAdmin):
    list_display = ["name_ar", "days", "price", "is_active"]


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ["listing", "package", "status", "starts_at", "ends_at"]
    list_filter = ["status"]


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ["user", "promotion", "amount", "currency", "status", "created_at"]
    list_filter = ["status", "method"]
