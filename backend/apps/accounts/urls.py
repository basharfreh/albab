from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from apps.accounts import views

urlpatterns = [
    path("auth/register/", views.RegisterView.as_view(), name="auth-register"),
    path("auth/login/", views.LoginView.as_view(), name="auth-login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="auth-refresh"),
    path("auth/otp/request/", views.OtpRequestView.as_view(), name="auth-otp-request"),
    path("auth/otp/verify/", views.OtpVerifyView.as_view(), name="auth-otp-verify"),
    path("auth/me/", views.MeView.as_view(), name="auth-me"),
    path("admin/users/", views.AdminUserListView.as_view(), name="admin-users"),
    path(
        "admin/users/<int:pk>/block/", views.AdminUserBlockView.as_view(), name="admin-user-block"
    ),
    path("admin/users/<int:pk>/role/", views.AdminUserRoleView.as_view(), name="admin-user-role"),
]
