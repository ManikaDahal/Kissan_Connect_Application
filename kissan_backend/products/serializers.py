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
    sentiment = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ('id', 'product', 'user', 'username', 'rating', 'comment', 'sentiment', 'created_at')
        read_only_fields = ('user',)

    def get_sentiment(self, obj):
        from .services import analyze_sentiment
        return analyze_sentiment(obj.comment)


class ProductSerializer(serializers.ModelSerializer):
    category_name = serializers.SerializerMethodField()
    image = serializers.ImageField(required=False, allow_null=True)
    reviews = ReviewSerializer(many=True, read_only=True)
    average_rating = serializers.ReadOnlyField()
    total_reviews = serializers.ReadOnlyField()
    seller_name = serializers.ReadOnlyField(source='seller.full_name')
    shop_name = serializers.ReadOnlyField(source='seller.seller_profile.shop_name')
    shop_address = serializers.ReadOnlyField(source='seller.seller_profile.shop_address')
    distance = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'description',
            'price', 'discount_price', 'stock', 'weight', 'unit_type', 'image', 'is_famous',
            'approval_status', 'admin_note',
            'created_at', 'reviews', 'average_rating', 'total_reviews',
            'seller', 'seller_name', 'shop_name', 'shop_address', 'distance',
        )

    def get_distance(self, obj):
        val = getattr(obj, 'distance', None)
        return float(val) if val is not None else None

    def validate(self, data):
        price = data.get('price')
        discount_price = data.get('discount_price')

        if price is None and self.instance:
            price = self.instance.price

        if 'discount_price' in data and discount_price is not None:
            if price is not None and discount_price >= price:
                raise serializers.ValidationError({"discount_price": "Discount price must be less than original price."})
            if discount_price <= 0:
                raise serializers.ValidationError({"discount_price": "Discount price must be greater than zero."})
        return data

    def get_category_name(self, obj):
        return obj.category.name if obj.category else "Uncategorized"

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.image:
            url = instance.image.url
            if 'cloudinary' in url and '/upload/' in url:
                representation['image'] = url.replace('/upload/', '/upload/f_jpg/')
            else:
                representation['image'] = url
        else:
            representation['image'] = None
        return representation


class ProductListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing products — no embedded reviews."""
    category_name = serializers.SerializerMethodField()
    average_rating = serializers.ReadOnlyField()
    total_reviews = serializers.ReadOnlyField()
    shop_name = serializers.ReadOnlyField(source='seller.seller_profile.shop_name')
    shop_address = serializers.ReadOnlyField(source='seller.seller_profile.shop_address')
    distance = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'description',
            'price', 'discount_price', 'stock', 'weight', 'unit_type', 'image', 'is_famous',
            'approval_status', 'admin_note',
            'created_at', 'average_rating', 'total_reviews', 'shop_name', 'shop_address', 'distance',
        )

    def get_distance(self, obj):
        val = getattr(obj, 'distance', None)
        return float(val) if val is not None else None

    def get_category_name(self, obj):
        return obj.category.name if obj.category else "Uncategorized"

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.image:
            url = instance.image.url
            if 'cloudinary' in url and '/upload/' in url:
                representation['image'] = url.replace('/upload/', '/upload/f_jpg/')
            else:
                representation['image'] = url
        else:
            representation['image'] = None
        return representation


class CategorySuggestionSerializer(serializers.ModelSerializer):
    seller_name = serializers.ReadOnlyField(source='seller.full_name')

    class Meta:
        model = CategorySuggestion
        fields = ('id', 'name', 'reason', 'status', 'admin_note', 'seller_name', 'created_at', 'reviewed_at')
        read_only_fields = ('status', 'admin_note', 'seller_name', 'reviewed_at')
