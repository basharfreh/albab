import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.accounts.tests.factories import UserFactory


@pytest.mark.django_db
class TestRegister:
    def test_register_creates_user_and_normalizes_phone(self):
        client = APIClient()
        response = client.post(
            reverse("auth-register"),
            {
                "phone": "0987 654 321",
                "name": "خالد",
                "password": "StrongPass123",
                "role": "seeker",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        user = User.objects.get(phone="+963987654321")
        assert user.name == "خالد"
        assert user.check_password("StrongPass123")

    def test_register_duplicate_phone_rejected(self):
        UserFactory(phone="+963987654321")
        client = APIClient()
        response = client.post(
            reverse("auth-register"),
            {
                "phone": "+963987654321",
                "name": "آخر",
                "password": "StrongPass123",
                "role": "seeker",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "phone" in response.data

    def test_register_duplicate_phone_same_raw_format_rejected(self):
        client = APIClient()
        payload = {
            "phone": "0955000111",
            "name": "A",
            "password": "StrongPass123",
            "role": "seeker",
        }
        first = client.post(reverse("auth-register"), payload, format="json")
        assert first.status_code == status.HTTP_201_CREATED

        second = client.post(
            reverse("auth-register"),
            {**payload, "name": "B"},
            format="json",
        )
        assert second.status_code == status.HTTP_400_BAD_REQUEST
        assert "phone" in second.data


@pytest.mark.django_db
class TestLogin:
    def test_login_with_different_phone_format_succeeds(self):
        UserFactory(phone="+963987654321", password="StrongPass123")
        client = APIClient()
        response = client.post(
            reverse("auth-login"),
            {"phone": "+963 987 654 321", "password": "StrongPass123"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data
        assert "refresh" in response.data

    def test_login_wrong_password_fails(self):
        UserFactory(phone="+963987654321", password="StrongPass123")
        client = APIClient()
        response = client.post(
            reverse("auth-login"),
            {"phone": "+963987654321", "password": "WrongPass"},
            format="json",
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert response.data["detail"] == "رقم الهاتف أو كلمة المرور غير صحيحة."


@pytest.mark.django_db
class TestMe:
    def test_me_requires_auth(self):
        client = APIClient()
        response = client.get(reverse("auth-me"))
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_me_returns_profile(self):
        user = UserFactory(phone="+963987654321", password="StrongPass123")
        client = APIClient()
        client.force_authenticate(user)
        response = client.get(reverse("auth-me"))
        assert response.status_code == status.HTTP_200_OK
        assert response.data["phone"] == "+963987654321"
