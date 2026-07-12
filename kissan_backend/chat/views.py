from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer
from users.models import User
from kissan_core.firebase_helper import send_push


class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Conversation.objects.filter(Q(participant_a=self.request.user) | Q(participant_b=self.request.user)).prefetch_related('messages')

    @action(detail=False, methods=['post'])
    def get_or_create(self, request):
        other_user_id = request.data.get('user_id')
        if not other_user_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            other_user_id = int(other_user_id)
        except (TypeError, ValueError):
            return Response({'error': 'user_id must be an integer'}, status=status.HTTP_400_BAD_REQUEST)

        other_user = User.objects.filter(id=other_user_id).first()
        if not other_user:
            return Response({'error': 'user not found'}, status=status.HTTP_400_BAD_REQUEST)

        conversation = Conversation.objects.filter(
            Q(participant_a=request.user, participant_b=other_user) |
            Q(participant_a=other_user, participant_b=request.user)
        ).first()

        if not conversation:
            conversation = Conversation.objects.create(participant_a=request.user, participant_b=other_user)

        return Response({'conversation_id': conversation.id})


class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        conversation_id = self.request.query_params.get('conversation_id')
        if not conversation_id:
            return Message.objects.none()
        return Message.objects.filter(conversation_id=conversation_id).order_by('created_at')

    def perform_create(self, serializer):
        recipient = serializer.validated_data.get('recipient')
        message = serializer.save(sender=self.request.user, recipient=recipient or self.request.user)

        if recipient and recipient != self.request.user:
            try:
                send_push(
                    user=recipient,
                    title='New message',
                    body=f'{self.request.user.full_name or self.request.user.email}: {message.content[:80]}',
                    data={
                        'route': 'chat',
                        'conversation_id': message.conversation.id,
                        'other_user_id': self.request.user.id,
                        'other_user_name': self.request.user.full_name or self.request.user.email,
                    },
                )
            except Exception as e:
                print(f'Chat notification error: {e}')
