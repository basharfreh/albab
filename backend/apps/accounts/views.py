from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.exceptions import ValidationError
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from apps.accounts.models import User, UserRole
from apps.accounts.otp.service import request_otp, verify_otp
from apps.accounts.serializers import (
    AdminUserSerializer,
    MeSerializer,
    OtpRequestSerializer,
    OtpVerifySerializer,
    PhoneTokenObtainPairSerializer,
    RegisterSerializer,
)
from apps.common.permissions import IsAdminRole


class RegisterView(generics.CreateAPIView):
    """UC-02: register with phone + name + password, choosing a role."""

    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"


class LoginView(TokenObtainPairView):
    """UC-03: log in with phone + password. Accepts any input phone format."""

    serializer_class = PhoneTokenObtainPairSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"


class OtpRequestView(APIView):
    """UC-04 (1/2): request an OTP code for a phone number."""

    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = OtpRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = request_otp(**serializer.validated_data)
        return Response(result)


class OtpVerifyView(APIView):
    """UC-04 (2/2): verify an OTP code, marking the phone verified if a user owns it."""

    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = OtpVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data["phone"]
        verify_otp(
            phone=phone,
            purpose=serializer.validated_data["purpose"],
            code=serializer.validated_data["code"],
        )
        User.objects.filter(phone=phone).update(is_phone_verified=True)
        return Response({"verified": True})


class MeView(generics.RetrieveUpdateAPIView):
    """UC-06: view / edit the authenticated user's own profile."""

    serializer_class = MeSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_object(self):
        return self.request.user


class AdminUserListView(generics.ListAPIView):
    """UC-55: search users, filter by role."""

    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminRole]
    filterset_fields = ["role"]

    def get_queryset(self):
        queryset = User.objects.all()
        query = self.request.query_params.get("q", "").strip()
        if query:
            queryset = queryset.filter(Q(name__icontains=query) | Q(phone__icontains=query))
        return queryset


class AdminUserBlockView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        user = get_object_or_404(User, pk=pk)
        user.is_blocked = bool(request.data.get("blocked", True))
        user.save(update_fields=["is_blocked"])
        return Response(AdminUserSerializer(user).data)


class AdminUserRoleView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        role = request.data.get("role")
        if role not in UserRole.values:
            raise ValidationError({"role": ["قيمة غير صالحة."]})
        user = get_object_or_404(User, pk=pk)
        user.role = role
        user.save(update_fields=["role"])
        return Response(AdminUserSerializer(user).data)
