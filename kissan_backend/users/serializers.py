from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, UserAddress


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'phone_number', 'is_verified', 'date_joined']
        read_only_fields = ['id', 'is_verified', 'date_joined']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = ['email', 'full_name', 'password']

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            full_name=validated_data.get('full_name', ''),
        )
        return user


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAddress
        fields = [
            'id', 'user', 'full_name', 'phone_number', 
            'province', 'city', 'area', 'house_no', 'is_default'
        ]
        read_only_fields = ['user']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        # If this is set as default, unset other default addresses for this user
        if validated_data.get('is_default'):
            UserAddress.objects.filter(user=validated_data['user'], is_default=True).update(is_default=False)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if validated_data.get('is_default'):
            UserAddress.objects.filter(user=instance.user, is_default=True).update(is_default=False)
        return super().update(instance, validated_data)
