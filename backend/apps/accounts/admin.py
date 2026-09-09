from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from apps.accounts.models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    model = User
    ordering = ["-created_at"]
    list_display = ["phone", "name", "role", "is_phone_verified", "is_blocked", "is_staff"]
    list_filter = ["role", "is_blocked", "is_phone_verified"]
    search_fields = ["phone", "name", "agency_name"]
    readonly_fields = ["created_at", "last_login"]
    fieldsets = (
        (None, {"fields": ("phone", "password")}),
        (
            "Profile",
            {"fields": ("name", "avatar", "role", "agency_name", "agency_logo", "whatsapp_phone")},
        ),
        (
            "Status",
            {
                "fields": (
                    "is_phone_verified",
                    "is_blocked",
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Dates", {"fields": ("last_login", "created_at")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("phone", "name", "role", "password1", "password2"),
            },
        ),
    )
