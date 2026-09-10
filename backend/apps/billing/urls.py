from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.billing import views

router = DefaultRouter()
router.register(
    "admin/promotion-packages",
    views.AdminPromotionPackageViewSet,
    basename="admin-promotion-package",
)

urlpatterns = [
    path(
        "admin/promotions/", views.AdminPromotionListCreateView.as_view(), name="admin-promotions"
    ),
    path(
        "admin/transactions/",
        views.AdminTransactionListCreateView.as_view(),
        name="admin-transactions",
    ),
] + router.urls
