from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OrderViewSet, stripe_webhook, seller_orders

router = DefaultRouter()
router.register(r'orders', OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    path('stripe-webhook/', stripe_webhook, name='stripe-webhook'),
    path('seller-orders/', seller_orders, name='seller-orders'),
]
