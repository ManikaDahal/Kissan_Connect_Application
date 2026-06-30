from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OrderViewSet, stripe_webhook, seller_orders, update_item_status, seller_earnings

router = DefaultRouter()
router.register(r'orders', OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    path('stripe-webhook/', stripe_webhook, name='stripe-webhook'),
    path('seller-orders/', seller_orders, name='seller-orders'),
    path('seller-orders/items/<int:item_id>/status/', update_item_status, name='update-item-status'),
    path('seller-orders/earnings/', seller_earnings, name='seller-earnings'),
]
