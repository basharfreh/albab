from rest_framework.routers import DefaultRouter

from apps.common import views

router = DefaultRouter()
router.register("admin/settings/pages", views.AdminStaticPageViewSet, basename="admin-static-page")

urlpatterns = router.urls
