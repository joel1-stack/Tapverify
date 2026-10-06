from django.urls import path

from . import views

urlpatterns = [
    # Secretary API
    path('api/auth/otp/', views.RequestOTPView.as_view()),
    path('api/auth/verify/', views.VerifyOTPView.as_view()),
    path('api/auth/register/', views.RegisterView.as_view()),
    path('api/me/', views.MeView.as_view()),
    path('api/collections/', views.CollectionsView.as_view()),
    path('api/collections/<int:pk>/', views.CollectionDetailView.as_view()),
    path('api/collections/<int:pk>/remind-unpaid/', views.RemindUnpaidView.as_view()),
    path('api/collections/<int:pk>/export.csv', views.CollectionExportView.as_view()),
    path('api/members/<int:pk>/mark-paid/', views.MarkPaidView.as_view()),
    path('api/members/<int:pk>/remind/', views.RemindMemberView.as_view()),

    # Member payment experience (public)
    path('p/<str:pay_code>/', views.pay_page, name='pay-page'),
    path('api/p/<str:pay_code>/', views.PayInfoView.as_view(), name='pay-info'),
    path('api/p/<str:pay_code>/pay/', views.PayStartView.as_view(),
         name='pay-start'),

    # Payment provider callbacks
    path('api/webhooks/sasapay/', views.SasaPayWebhookView.as_view(),
         name='sasapay-webhook'),
]
