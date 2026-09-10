from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.catalog import views

router = DefaultRouter()
router.register("listings", views.ListingViewSet, basename="listing")
router.register(
    "admin/neighborhoods", views.AdminNeighborhoodViewSet, basename="admin-neighborhood"
)

urlpatterns = [
    path("neighborhoods/", views.NeighborhoodListView.as_view(), name="neighborhoods"),
    path(
        "admin/settings/quotas/",
        views.AdminQuotaSettingsView.as_view(),
        name="admin-quota-settings",
    ),
    path("me/listings/", views.MyListingsView.as_view(), name="my-listings"),
    path("favorites/", views.FavoriteListCreateView.as_view(), name="favorites"),
    path(
        "favorites/<int:listing_id>/",
        views.FavoriteDeleteView.as_view(),
        name="favorite-detail",
    ),
    path(
        "listings/<int:listing_id>/images/",
        views.ListingImageListCreateView.as_view(),
        name="listing-images",
    ),
    path(
        "listings/<int:listing_id>/images/reorder/",
        views.ListingImageReorderView.as_view(),
        name="listing-images-reorder",
    ),
    path(
        "listings/<int:listing_id>/images/<int:image_id>/",
        views.ListingImageDetailView.as_view(),
        name="listing-image-detail",
    ),
    path("geo/search/", views.GeoSearchView.as_view(), name="geo-search"),
    path("geo/reverse/", views.GeoReverseView.as_view(), name="geo-reverse"),
] + router.urls
