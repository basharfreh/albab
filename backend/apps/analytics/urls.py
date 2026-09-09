from django.urls import path

from apps.analytics import views

urlpatterns = [
    path(
        "listings/<int:listing_id>/events/",
        views.ListingEventCreateView.as_view(),
        name="listing-events",
    ),
    path("me/listings/stats/", views.OwnerListingStatsView.as_view(), name="my-listings-stats"),
    path("admin/kpis/", views.AdminKpisView.as_view(), name="admin-kpis"),
    path("admin/analytics/visits/", views.AdminVisitsView.as_view(), name="admin-visits"),
    path("admin/analytics/by-type/", views.AdminByTypeView.as_view(), name="admin-by-type"),
]
