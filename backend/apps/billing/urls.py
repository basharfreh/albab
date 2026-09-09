from django.urls import path

from apps.billing import views

urlpatterns = [
    path(
        "admin/promotions/", views.AdminPromotionListCreateView.as_view(), name="admin-promotions"
    ),
    path(
        "admin/transactions/",
        views.AdminTransactionListCreateView.as_view(),
        name="admin-transactions",
    ),
]
