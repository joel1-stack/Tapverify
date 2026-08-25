from django.urls import path
from django.contrib import admin
from . import views
from .webhook_handler import sasapay_webhook, sasapay_webhook_test
from .ussd_handler import ussd_handler

urlpatterns = [
    path('admin/', admin.site.urls),

    # Web Dashboard
    path('', views.dashboard_view, name='web-dashboard'),
    path('login/', views.web_login_view, name='web-login'),
    path('logout/', views.web_logout_view, name='web-logout'),
    path('collections/new/', views.create_collection_view, name='web-create-collection'),
    path('collections/<uuid:collection_id>/', views.collection_detail_view, name='web-collection-detail'),
    path('collections/<uuid:collection_id>/generate-links/', views.generate_links_view, name='web-generate-links'),
    path('collections/<uuid:collection_id>/remind/', views.remind_pending_view, name='web-remind'),
    path('collections/<uuid:collection_id>/reconcile/', views.reconcile_view, name='web-reconcile'),
    path('members/', views.members_view, name='web-members'),
    path('settings/', views.settings_view, name='web-settings'),

    # Auth
    path('api/v1/auth/login/', views.StaffLoginView.as_view(), name='staff-login'),

    # Members
    path('api/v1/members/', views.MemberListView.as_view(), name='member-list'),
    path('api/v1/members/<uuid:pk>/', views.MemberDetailView.as_view(), name='member-detail'),
    path('api/v1/members/<uuid:member_id>/history/', views.MemberHistoryView.as_view(), name='member-history'),

    # Verification (Core)
    path('api/v1/verify/', views.VerifyMemberView.as_view(), name='verify-member'),

    # Receipt Portal
    path('r/<str:token>/', views.receipt_view, name='receipt-view'),

    # Dashboard
    path('api/v1/stats/', views.WorkspaceStatsView.as_view(), name='workspace-stats'),

    # Reminders
    path('api/v1/reminders/send/', views.SendRemindersView.as_view(), name='send-reminders'),

    # Payment Links (member pays on own phone)
    path('api/v1/payment-link/create/', views.PaymentLinkCreateView.as_view(), name='payment-link-create'),
    path('pay/<str:token>/', views.payment_link_view, name='payment-link-view'),
    path('pay/<str:token>/pay/', views.payment_link_pay, name='payment-link-pay'),
    path('pay/<str:token>/status/', views.payment_link_status, name='payment-link-status'),

    # Payment Rails
    path('api/v1/rail/info/', views.payment_rail_info, name='payment-rail-info'),

    # SasaPay Webhook
    path('webhooks/sasapay/', sasapay_webhook, name='sasapay-webhook'),
    path('webhooks/sasapay/test/', sasapay_webhook_test, name='sasapay-webhook-test'),

    # USSD
    path('ussd/', ussd_handler, name='ussd-handler'),
]
