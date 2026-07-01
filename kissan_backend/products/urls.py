from django.urls import path
from .views import (
    CategoryListCreateView, CategoryDetailView,
    ProductListCreateView, ProductDetailView,
    ReviewListCreateView, SellerProductViewSet,
    CategorySuggestionViewSet
)
from rest_framework.routers import DefaultRouter

urlpatterns = [
    path('categories/', CategoryListCreateView.as_view(), name='category-list'),
    path('categories/<int:pk>/', CategoryDetailView.as_view(), name='category-detail'),
    path('products/', ProductListCreateView.as_view(), name='product-list'),
    path('products/<int:pk>/', ProductDetailView.as_view(), name='product-detail'),
    path('reviews/', ReviewListCreateView.as_view(), name='review-list'),
]

router = DefaultRouter()
router.register('seller/my-items', SellerProductViewSet, basename='seller-products')
router.register('seller/category-suggestions', CategorySuggestionViewSet, basename='seller-category-suggestions')
urlpatterns += router.urls
