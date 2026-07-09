from rest_framework import generics, permissions, status, views
from rest_framework.response import Response
from .models import Cart, CartItem
from .serializers import CartSerializer, CartItemSerializer
from products.models import Product

class CartDetailView(generics.RetrieveAPIView):
    """Fetch the current authenticated user's cart and its items."""
    serializer_class = CartSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        cart, _ = Cart.objects.get_or_create(user=self.request.user)
        return Cart.objects.prefetch_related(
            'items__product__category',
            'items__product__seller__seller_profile',
            'items__product__reviews'
        ).get(id=cart.id)

class AddToCartView(views.APIView):
    """Add a product to the cart or update its quantity."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity', 1))
        
        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
            
        if product.seller == request.user:
            return Response({'error': 'Sellers cannot buy their own products.'}, status=status.HTTP_400_BAD_REQUEST)
            
        cart, _ = Cart.objects.get_or_create(user=self.request.user)
        cart_item, created = CartItem.objects.get_or_create(cart=cart, product=product)
        
        if not created:
            cart_item.quantity += quantity
        else:
            cart_item.quantity = quantity
            
        cart_item.save()
        return Response(CartItemSerializer(cart_item).data, status=status.HTTP_201_CREATED)

class UpdateCartItemView(views.APIView):
    """Explicitly set the quantity of a product in the cart."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity'))
        
        try:
            product = Product.objects.get(id=product_id)
            if product.seller == request.user:
                return Response({'error': 'Sellers cannot buy their own products.'}, status=status.HTTP_400_BAD_REQUEST)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
            
        if quantity <= 0:
            cart = Cart.objects.get(user=self.request.user)
            CartItem.objects.filter(cart=cart, product_id=product_id).delete()
            return Response({'message': 'Item removed from cart'}, status=status.HTTP_200_OK)

        cart, _ = Cart.objects.get_or_create(user=self.request.user)
        cart_item, created = CartItem.objects.get_or_create(cart=cart, product_id=product_id)
        cart_item.quantity = quantity
        cart_item.save()
        return Response(CartItemSerializer(cart_item).data, status=status.HTTP_200_OK)


class RemoveFromCartView(views.APIView):
    """Remove a product entirely from the user's cart."""
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, product_id):
        try:
            cart = Cart.objects.get(user=self.request.user)
            CartItem.objects.filter(cart=cart, product_id=product_id).delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Cart.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

class ClearCartView(views.APIView):
    """Remove all items from the current user's cart."""
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        try:
            cart = Cart.objects.get(user=self.request.user)
            cart.items.all().delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Cart.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
