from rest_framework import generics, permissions, filters, viewsets
from .models import Category, Product, Review
from .serializers import CategorySerializer, ProductSerializer, ProductListSerializer, ReviewSerializer
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
        return Product.objects.select_related('category').all()

class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.select_related('category').prefetch_related('reviews__user')
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
        serializer.save(user=self.request.user)


class SellerProductViewSet(viewsets.ModelViewSet):
    """ViewSet for sellers to manage their own inventory."""
    serializer_class = ProductSerializer
    permission_classes = [IsSeller, IsProductOwner]

    def get_queryset(self):
        return Product.objects.filter(seller=self.request.user)

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
