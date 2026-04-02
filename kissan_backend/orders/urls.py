from .views import OrderViewSet, stripe_webhook

router = DefaultRouter()
router.register(r'orders', OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    path('stripe-webhook/', stripe_webhook, name='stripe-webhook'),
]
