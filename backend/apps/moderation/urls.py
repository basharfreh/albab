from django.urls import path

from apps.moderation import views

urlpatterns = [
    path(
        "listings/<int:listing_id>/report/", views.ReportCreateView.as_view(), name="listing-report"
    ),
    path("admin/listings/", views.AdminListingQueueView.as_view(), name="admin-listings"),
    path(
        "admin/listings/<int:pk>/approve/",
        views.ApproveListingView.as_view(),
        name="admin-listing-approve",
    ),
    path(
        "admin/listings/<int:pk>/reject/",
        views.RejectListingView.as_view(),
        name="admin-listing-reject",
    ),
    path("admin/reports/", views.AdminReportsListView.as_view(), name="admin-reports"),
    path(
        "admin/reports/<int:pk>/close/", views.ReportCloseView.as_view(), name="admin-report-close"
    ),
]
