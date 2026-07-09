from rest_framework import generics, permissions, filters, viewsets
from .models import Category, Product, Review, CategorySuggestion
from .serializers import CategorySerializer, ProductSerializer, ProductListSerializer, ReviewSerializer, CategorySuggestionSerializer
from django_filters.rest_framework import DjangoFilterBackend
from users.permissions import IsSeller, IsProductOwner
from rest_framework.decorators import action
from rest_framework.response import Response

class CategoryListCreateView(generics.ListCreateAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]

class CategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]

class ProductListCreateView(generics.ListCreateAPIView):
    serializer_class = ProductListSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'is_famous']
    search_fields = ['name']
    ordering_fields = ['price', 'created_at', 'name']

    def get_queryset(self):
        return Product.objects.select_related(
            'category',
            'seller',
            'seller__seller_profile'
        ).prefetch_related(
            'reviews'
        ).all()

class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.select_related(
        'category',
        'seller',
        'seller__seller_profile'
    ).prefetch_related(
        'reviews',
        'reviews__user'
    )
    serializer_class = ProductSerializer
    permission_classes = [permissions.AllowAny]

class ReviewListCreateView(generics.ListCreateAPIView):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    
    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        product = serializer.validated_data.get('product')
        if product and product.seller == self.request.user:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("You cannot review your own product.")
        serializer.save(user=self.request.user)


class SellerProductViewSet(viewsets.ModelViewSet):
    """ViewSet for sellers to manage their own inventory."""
    serializer_class = ProductSerializer
    permission_classes = [IsSeller, IsProductOwner]

    def get_queryset(self):
        return Product.objects.filter(seller=self.request.user).select_related(
            'category',
            'seller',
            'seller__seller_profile'
        ).prefetch_related(
            'reviews',
            'reviews__user'
        )

    def perform_create(self, serializer):
        serializer.save(seller=self.request.user)

    @action(detail=True, methods=['patch'], url_path='update-stock')
    def update_stock(self, request, pk=None):
        """Quickly update the stock of a product."""
        product = self.get_object()
        new_stock = request.data.get('stock')
        if new_stock is not None:
            product.stock = int(new_stock)
            product.save()
            return Response({'status': 'stock updated', 'new_stock': product.stock})
        return Response({'error': 'Stock value required'}, status=400)

    @action(detail=True, methods=['patch'], url_path='update-price')
    def update_price(self, request, pk=None):
        """Quickly update the price of a product."""
        product = self.get_object()
        new_price = request.data.get('price')
        if new_price is not None:
            product.price = new_price
            product.save()
            return Response({'status': 'price updated', 'new_price': str(product.price)})
        return Response({'error': 'Price value required'}, status=400)


class CategorySuggestionViewSet(viewsets.ModelViewSet):
    """ViewSet for sellers to submit and track their category suggestions."""
    serializer_class = CategorySuggestionSerializer
    permission_classes = [permissions.IsAuthenticated, IsSeller]

    def get_queryset(self):
        return CategorySuggestion.objects.filter(seller=self.request.user)

    def perform_create(self, serializer):
        serializer.save(seller=self.request.user)
