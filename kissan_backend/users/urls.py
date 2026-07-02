from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    SendOTPView, VerifyOTPView, RegisterView,
    LoginView, LogoutView, GoogleLoginView,
    ForgotPasswordView, VerifyResetOTPView, ResetPasswordView,
    ChangePasswordView, ProfileView, BiometricTokenRefreshView,
    SellerApplyView, SellerStatusView, SupportTicketView,
)

urlpatterns = [
    path('otp/send/',   SendOTPView.as_view(),   name='send-otp'),
    path('otp/verify/', VerifyOTPView.as_view(), name='verify-otp'),

    path('register/', RegisterView.as_view(), name='register'),
    path('login/',         LoginView.as_view(),       name='login'),
    path('login/google/',  GoogleLoginView.as_view(),  name='google-login'),
    path('logout/',        LogoutView.as_view(),      name='logout'),

    path('token/refresh/', BiometricTokenRefreshView.as_view(), name='token-refresh'),

    path('password/forgot/',       ForgotPasswordView.as_view(),   name='forgot-password'),
    path('password/verify-otp/',   VerifyResetOTPView.as_view(),   name='verify-reset-otp'),
    path('password/reset/',        ResetPasswordView.as_view(),    name='reset-password'),

    path('password/change/',  ChangePasswordView.as_view(), name='change-password'),
    path('profile/',          ProfileView.as_view(),         name='profile'),
    
    # Seller Onboarding
    path('seller/apply/',     SellerApplyView.as_view(),     name='seller-apply'),
    path('seller/status/',    SellerStatusView.as_view(),    name='seller-status'),
    
    # Customer Support Ticket
    path('support/ticket/',   SupportTicketView.as_view(),   name='support-ticket'),
]

from rest_framework.routers import DefaultRouter
from .views import AddressViewSet

router = DefaultRouter()
router.register('addresses', AddressViewSet, basename='address')
urlpatterns += router.urls
