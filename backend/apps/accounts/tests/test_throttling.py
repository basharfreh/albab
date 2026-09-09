import pytest
from django.urls import reverse
from rest_framework.test import APIClient


@pytest.mark.django_db
class TestAuthThrottle:
    def test_sixth_otp_request_in_a_minute_is_throttled(self):
        client = APIClient()
        for i in range(5):
            response = client.post(
                reverse("auth-otp-request"), {"phone": f"+96398765{i:04d}"}, format="json"
            )
            assert response.status_code == 200

        sixth = client.post(reverse("auth-otp-request"), {"phone": "+963987650099"}, format="json")
        assert sixth.status_code == 429
