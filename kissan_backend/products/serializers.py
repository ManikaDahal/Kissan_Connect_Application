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
    username = serializers.ReadOnlyField(source='user.name')

    class Meta:
        model = Review
        fields = ('id', 'product', 'user', 'username', 'rating', 'comment', 'created_at')

class ProductSerializer(serializers.ModelSerializer):
    category_name = serializers.ReadOnlyField(source='category.name')
    image = serializers.SerializerMethodField()
    reviews = ReviewSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = ('id', 'name', 'category', 'category_name', 'description', 'price', 'stock', 'weight', 'image', 'is_famous', 'created_at', 'reviews')

    def get_image(self, obj):
        if obj.image:
            return obj.image.url
        return None
