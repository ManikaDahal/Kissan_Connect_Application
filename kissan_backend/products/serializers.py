from rest_framework import serializers
from .models import Category, Product, Review

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

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'description', 
            'price', 'stock', 'weight', 'image', 'is_famous', 
            'created_at', 'reviews', 'average_rating', 'total_reviews'
        )

    def get_category_name(self, obj):
        return obj.category.name if obj.category else "Uncategorized"

    def get_image(self, obj):
        if obj.image:
            return obj.image.url
        return None

class ProductListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing products - no embedded reviews."""
    category_name = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    average_rating = serializers.ReadOnlyField()
    total_reviews = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'description',
            'price', 'stock', 'weight', 'image', 'is_famous',
            'created_at', 'average_rating', 'total_reviews'
        )

    def get_category_name(self, obj):
        return obj.category.name if obj.category else "Uncategorized"

    def get_image(self, obj):
        if obj.image:
            return obj.image.url
        return None
