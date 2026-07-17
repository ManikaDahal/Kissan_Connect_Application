from rest_framework import serializers
from .models import Conversation, Message


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'conversation', 'sender', 'recipient', 'content', 'image', 'created_at', 'is_read']
        read_only_fields = ['id', 'sender', 'created_at', 'is_read']

    def validate(self, attrs):
        content = attrs.get('content')
        image = attrs.get('image')
        if not content and not image:
            raise serializers.ValidationError('Message must contain text content or an image.')
        return attrs

    def validate_recipient(self, value):
        request_user = self.context.get('request').user if self.context.get('request') else None
        if request_user and value == request_user:
            raise serializers.ValidationError('Choose another participant for this conversation.')
        return value


class ConversationSerializer(serializers.ModelSerializer):
    participant_name = serializers.SerializerMethodField()
    shop_name = serializers.SerializerMethodField()
    other_user_id = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    last_message_time = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ['id', 'participant_a', 'participant_b', 'participant_name', 'shop_name', 'other_user_id', 'last_message', 'last_message_time', 'created_at']

    def _get_other_user(self, obj):
        request = self.context.get('request')
        request_user = request.user if request else None
        if request_user is None:
            return obj.participant_b
        return obj.participant_b if obj.participant_a == request_user else obj.participant_a

    def get_participant_name(self, obj):
        other_user = self._get_other_user(obj)
        try:
            shop = other_user.seller_profile.shop_name
            if shop:
                return shop
        except Exception:
            pass
        return other_user.full_name or other_user.email

    def get_shop_name(self, obj):
        other_user = self._get_other_user(obj)
        try:
            shop = other_user.seller_profile.shop_name
            if shop:
                return shop
        except Exception:
            pass
        return None

    def get_other_user_id(self, obj):
        other_user = self._get_other_user(obj)
        return other_user.id

    def get_last_message(self, obj):
        last_message = obj.messages.order_by('-created_at').first()
        return last_message.content if last_message else ''

    def get_last_message_time(self, obj):
        last_message = obj.messages.order_by('-created_at').first()
        return last_message.created_at.isoformat() if last_message else None

