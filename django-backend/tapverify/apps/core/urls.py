from django.urls import path
from django.contrib import admin
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/login/', views.StaffLoginView.as_view(), name='staff-login'),
    path('api/v1/members/', views.MemberListView.as_view(), name='member-list'),
    path('api/v1/members/<uuid:pk>/', views.MemberDetailView.as_view(), name='member-detail'),
    path('api/v1/members/<uuid:member_id>/history/', views.MemberHistoryView.as_view(), name='member-history'),
    path('api/v1/verify/', views.VerifyMemberView.as_view(), name='verify-member'),
    path('r/<str:token>/', views.receipt_view, name='receipt-view'),
    path('api/v1/stats/', views.WorkspaceStatsView.as_view(), name='workspace-stats'),
    path('api/v1/reminders/send/', views.SendRemindersView.as_view(), name='send-reminders'),
    path('api/v1/webhooks/mpesa/', views.mpesa_callback, name='mpesa-callback'),
    path('api/v1/demo/setup/', views.create_workspace_demo, name='demo-setup'),
]
