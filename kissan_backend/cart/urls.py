from django.urls import path
from .views import CartDetailView, AddToCartView, RemoveFromCartView, ClearCartView, UpdateCartItemView

urlpatterns = [
    path('', CartDetailView.as_view(), name='cart-detail'),
    path('add/', AddToCartView.as_view(), name='cart-add'),
    path('update/', UpdateCartItemView.as_view(), name='cart-update'),
    path('remove/<int:product_id>/', RemoveFromCartView.as_view(), name='cart-remove'),
    path('clear/', ClearCartView.as_view(), name='cart-clear'),
]
