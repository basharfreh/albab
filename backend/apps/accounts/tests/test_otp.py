from datetime import timedelta

import pytest
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from apps.accounts.models import OtpCode, OtpPurpose


@pytest.mark.django_db
class TestOtp:
    def test_request_then_verify_succeeds(self, settings):
        settings.DEBUG = True
        client = APIClient()

        response = client.post(
            reverse("auth-otp-request"),
            {"phone": "0987654321", "purpose": "register"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        code = response.data["debug_code"]

        verify_response = client.post(
            reverse("auth-otp-verify"),
            {"phone": "0987654321", "purpose": "register", "code": code},
            format="json",
        )
        assert verify_response.status_code == status.HTTP_200_OK
        assert verify_response.data["verified"] is True

    def test_verify_expired_code_fails(self):
        OtpCode.objects.create(
            phone="+963987654321",
            purpose=OtpPurpose.REGISTER,
            code_hash="irrelevant",
            expires_at=timezone.now() - timedelta(minutes=1),
        )
        client = APIClient()
        response = client.post(
            reverse("auth-otp-verify"),
            {"phone": "+963987654321", "purpose": "register", "code": "123456"},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
