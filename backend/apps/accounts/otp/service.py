import hashlib
import random
from datetime import timedelta

from django.conf import settings
from django.utils import timezone
from rest_framework.exceptions import Throttled, ValidationError

from apps.accounts.models import OtpCode
from apps.accounts.otp.backends import get_otp_backend

OTP_LENGTH = 6
OTP_TTL_MINUTES = 5
OTP_MAX_ATTEMPTS = 5
OTP_RESEND_SECONDS = 60


def _hash_code(phone: str, code: str) -> str:
    return hashlib.sha256(f"{phone}:{code}".encode()).hexdigest()


def request_otp(phone: str, purpose: str) -> dict:
    recent = OtpCode.objects.filter(phone=phone, purpose=purpose).order_by("-created_at").first()
    if recent and recent.created_at > timezone.now() - timedelta(seconds=OTP_RESEND_SECONDS):
        wait = OTP_RESEND_SECONDS - int((timezone.now() - recent.created_at).total_seconds())
        raise Throttled(wait=wait, detail="الرجاء الانتظار قبل طلب رمز جديد.")

    code = f"{random.randint(0, 999999):06d}"
    OtpCode.objects.create(
        phone=phone,
        purpose=purpose,
        code_hash=_hash_code(phone, code),
        expires_at=timezone.now() + timedelta(minutes=OTP_TTL_MINUTES),
    )
    get_otp_backend().send(phone, code)

    result = {"sent": True}
    if settings.DEBUG:
        result["debug_code"] = code
    return result


def verify_otp(phone: str, purpose: str, code: str) -> None:
    otp = (
        OtpCode.objects.filter(phone=phone, purpose=purpose, consumed_at__isnull=True)
        .order_by("-created_at")
        .first()
    )
    if otp is None:
        raise ValidationError({"code": ["لم يتم طلب رمز تحقق لهذا الرقم."]})
    if otp.expires_at < timezone.now():
        raise ValidationError({"code": ["انتهت صلاحية الرمز."]})
    if otp.attempts >= OTP_MAX_ATTEMPTS:
        raise ValidationError({"code": ["تم تجاوز عدد المحاولات المسموح."]})

    otp.attempts += 1
    otp.save(update_fields=["attempts"])

    if otp.code_hash != _hash_code(phone, code):
        raise ValidationError({"code": ["رمز التحقق غير صحيح."]})

    otp.consumed_at = timezone.now()
    otp.save(update_fields=["consumed_at"])
