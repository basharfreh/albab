from django.urls import path

from apps.engagement import views

urlpatterns = [
    path("conversations/", views.ConversationListCreateView.as_view(), name="conversations"),
    path(
        "conversations/<int:conversation_id>/messages/",
        views.ConversationMessagesView.as_view(),
        name="conversation-messages",
    ),
    path("notifications/", views.NotificationListView.as_view(), name="notifications"),
    path(
        "notifications/read-all/",
        views.NotificationReadAllView.as_view(),
        name="notifications-read-all",
    ),
    path(
        "notifications/<int:notification_id>/read/",
        views.NotificationMarkReadView.as_view(),
        name="notification-read",
    ),
]
