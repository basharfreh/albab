from rest_framework import viewsets
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.models import StaticPage
from apps.common.permissions import IsAdminRole
from apps.common.serializers import StaticPageSerializer


class HealthView(APIView):
    """Liveness check for the API."""

    permission_classes = [AllowAny]

    def get(self, request):
        return Response({"status": "ok", "version": "0.1.0"})


class AdminStaticPageViewSet(viewsets.ModelViewSet):
    """UC-59: CRUD for site-wide static content (about/terms/privacy/...)."""

    serializer_class = StaticPageSerializer
    permission_classes = [IsAdminRole]
    queryset = StaticPage.objects.all()
