import re

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

SYRIA_LOCAL_NUMBER_RE = re.compile(r"^9\d{8}$")


def normalize_syria_phone(raw: str) -> str:
    """Normalize a Syrian phone number to E.164 (+963XXXXXXXXX).

    Accepts 0987654321, 963987654321, +963987654321, and variants with spaces.
    """
    digits = re.sub(r"\D", "", raw or "")
    if digits.startswith("963"):
        national = digits[3:]
    elif digits.startswith("0"):
        national = digits[1:]
    else:
        national = digits

    if not SYRIA_LOCAL_NUMBER_RE.match(national):
        raise DjangoValidationError("رقم الهاتف غير صالح. الصيغة المطلوبة: 09XXXXXXXX")

    return f"+963{national}"


def normalize_phone_field(value: str) -> str:
    """Same as normalize_syria_phone, but raises a DRF-friendly error for serializer fields."""
    try:
        return normalize_syria_phone(value)
    except DjangoValidationError as exc:
        raise serializers.ValidationError(exc.messages) from exc
