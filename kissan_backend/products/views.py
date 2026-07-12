from rest_framework import generics, permissions, filters, viewsets
import threading
from .models import Category, Product, Review, CategorySuggestion
from .serializers import CategorySerializer, ProductSerializer, ProductListSerializer, ReviewSerializer, CategorySuggestionSerializer
from django_filters.rest_framework import DjangoFilterBackend
from users.permissions import IsSeller, IsProductOwner
from rest_framework.decorators import action
from rest_framework.response import Response
from kissan_core.firebase_helper import send_push, send_push_to_many

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
        ).filter(approval_status='approved')

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
        product = serializer.save(seller=self.request.user)

        # --- Push Notification: Notify all buyers that a new product is available ---
        def _notify_buyers():
            try:
                from users.models import User
                buyers = list(User.objects.filter(role='buyer'))
                if buyers:
                    send_push_to_many(
                        users=buyers,
                        title='🌱 New Product on KissanConnect!',
                        body=f'{product.name} is now available. Check it out!',
                        data={'route': 'home'},
                    )
            except Exception as e:
                print(f'New product notification error: {e}')
        threading.Thread(target=_notify_buyers).start()
        # -------------------------------------------------------------------------

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
        """Quickly update the price and discount price of a product."""
        product = self.get_object()
        previous_discount_price = product.discount_price
        new_price = request.data.get('price')
        discount_price = request.data.get('discount_price')

        updated = False
        if new_price is not None:
            product.price = new_price
            updated = True

        if 'discount_price' in request.data:
            if discount_price == '' or discount_price is None:
                product.discount_price = None
            else:
                product.discount_price = discount_price
            updated = True

        if updated:
            if product.discount_price is not None:
                from rest_framework.exceptions import ValidationError
                if product.discount_price >= product.price:
                    raise ValidationError("Discount price must be less than original price.")
                if product.discount_price <= 0:
                    raise ValidationError("Discount price must be greater than zero.")
            product.save()

            if 'discount_price' in request.data and product.discount_price is not None and (
                previous_discount_price is None or previous_discount_price != product.discount_price
            ):
                def _notify_discount():
                    try:
                        from users.models import User
                        if product.seller:
                            send_push(
                                user=product.seller,
                                title='💸 Discount Updated',
                                body=f'You added a discount to "{product.name}" for Rs {product.discount_price}.',
                                data={'route': 'seller_dashboard'},
                            )

                        buyers = list(User.objects.filter(role='buyer'))
                        if buyers:
                            send_push_to_many(
                                users=buyers,
                                title='💸 New Discount Alert!',
                                body=f'{product.name} is now available at a special discount of Rs {product.discount_price}.',
                                data={'route': 'home'},
                            )
                    except Exception as e:
                        print(f'Discount notification error: {e}')

                threading.Thread(target=_notify_discount).start()

            return Response({
                'status': 'price updated',
                'new_price': str(product.price),
                'new_discount_price': str(product.discount_price) if product.discount_price is not None else None
            })
        return Response({'error': 'Price or discount price value required'}, status=400)


class CategorySuggestionViewSet(viewsets.ModelViewSet):
    """ViewSet for sellers to submit and track their category suggestions."""
    serializer_class = CategorySuggestionSerializer
    permission_classes = [permissions.IsAuthenticated, IsSeller]

    def get_queryset(self):
        return CategorySuggestion.objects.filter(seller=self.request.user)

    def perform_create(self, serializer):
        serializer.save(seller=self.request.user)
