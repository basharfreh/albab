from rest_framework.permissions import BasePermission


class IsAdminRole(BasePermission):
    """Restricts a view to users with role=admin (the /admin/ API surface)."""

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.role == "admin")
