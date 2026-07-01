from rest_framework import serializers
from .models import Category, Product, Review, CategorySuggestion


class CategorySerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = '__all__'

    def get_image(self, obj):
        if obj.image:
            return obj.image.url
        return None


class ReviewSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.full_name')

    class Meta:
        model = Review
        fields = ('id', 'product', 'user', 'username', 'rating', 'comment', 'created_at')
        read_only_fields = ('user',)


class ProductSerializer(serializers.ModelSerializer):
    category_name = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    reviews = ReviewSerializer(many=True, read_only=True)
    average_rating = serializers.ReadOnlyField()
    total_reviews = serializers.ReadOnlyField()
    seller_name = serializers.ReadOnlyField(source='seller.full_name')
    shop_name = serializers.ReadOnlyField(source='seller.seller_profile.shop_name')
    shop_address = serializers.ReadOnlyField(source='seller.seller_profile.shop_address')

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'description',
            'price', 'stock', 'weight', 'unit_type', 'image', 'is_famous',
            'created_at', 'reviews', 'average_rating', 'total_reviews',
            'seller', 'seller_name', 'shop_name', 'shop_address',
        )

    def get_category_name(self, obj):
        return obj.category.name if obj.category else "Uncategorized"

    def get_image(self, obj):
        if obj.image:
            url = obj.image.url
            # Force Cloudinary to serve as JPG to avoid AVIF compression errors in Flutter
            if 'cloudinary' in url and '/upload/' in url:
                return url.replace('/upload/', '/upload/f_jpg/')
            return url
        return None


class ProductListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing products — no embedded reviews."""
    category_name = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    average_rating = serializers.ReadOnlyField()
    total_reviews = serializers.ReadOnlyField()
    shop_name = serializers.ReadOnlyField(source='seller.seller_profile.shop_name')
    shop_address = serializers.ReadOnlyField(source='seller.seller_profile.shop_address')

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'description',
            'price', 'stock', 'weight', 'unit_type', 'image', 'is_famous',
            'created_at', 'average_rating', 'total_reviews', 'shop_name', 'shop_address',
        )

    def get_category_name(self, obj):
        return obj.category.name if obj.category else "Uncategorized"

    def get_image(self, obj):
        if obj.image:
            url = obj.image.url
            if 'cloudinary' in url and '/upload/' in url:
                return url.replace('/upload/', '/upload/f_jpg/')
            return url
        return None


class CategorySuggestionSerializer(serializers.ModelSerializer):
    seller_name = serializers.ReadOnlyField(source='seller.full_name')

    class Meta:
        model = CategorySuggestion
        fields = ('id', 'name', 'reason', 'status', 'admin_note', 'seller_name', 'created_at', 'reviewed_at')
        read_only_fields = ('status', 'admin_note', 'seller_name', 'reviewed_at')
