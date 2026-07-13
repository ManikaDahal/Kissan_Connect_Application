from rest_framework import serializers
from .models import Order, OrderItem
from products.serializers import ProductSerializer
from users.serializers import AddressSerializer

class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    seller_id = serializers.ReadOnlyField(source='product.seller.id')
    seller_name = serializers.ReadOnlyField(source='product.seller.full_name')
    shop_name = serializers.ReadOnlyField(source='product.seller.seller_profile.shop_name')
    seller_email = serializers.ReadOnlyField(source='product.seller.email')

    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'seller_id', 'seller_name', 'shop_name', 'seller_email', 'quantity', 'price', 'status']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    user_email = serializers.ReadOnlyField(source='user.email')
    shipping_address = AddressSerializer(read_only=True)
    shipping_address_id = serializers.IntegerField(write_only=True, required=False)

    class Meta:
        model = Order
        fields = [
            'id', 'user_email', 'total_amount', 'status', 
            'payment_gateway', 'transaction_id', 'items', 
            'shipping_address', 'shipping_address_id', 'created_at'
        ]
        read_only_fields = ['status', 'transaction_id']
