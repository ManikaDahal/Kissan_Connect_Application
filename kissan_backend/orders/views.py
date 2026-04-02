import stripe
import os
import requests
from django.conf import settings
from rest_framework import viewsets, permissions, status, views
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from .models import Order, OrderItem
from .serializers import OrderSerializer
from products.models import Product

stripe.api_key = os.environ.get('STRIPE_SECRET_KEY')

class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        items_data = request.data.get('items', [])
        if not items_data:
            return Response({'error': 'No items provided'}, status=status.HTTP_400_BAD_REQUEST)

        total_amount = 0
        order_items = []

        for item in items_data:
            try:
                product = Product.objects.get(id=item['product'])
                qty = item['quantity']
                price = product.price
                total_amount += (price * qty)
                order_items.append(
                    OrderItem(
                        product=product,
                        quantity=qty,
                        price=price
                    )
                )
            except Product.DoesNotExist:
                return Response({'error': f"Product {item['product']} not found"}, status=status.HTTP_400_BAD_REQUEST)

        order = Order.objects.create(
            user=request.user,
            total_amount=total_amount,
            status='pending',
            payment_gateway=request.data.get('payment_gateway', 'cod')
        )

        for item in order_items:
            item.order = order
            item.save()

        serializer = self.get_serializer(order)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='create-stripe-payment-intent')
    def create_payment_intent(self, request, pk=None):
        order = self.get_object()
        try:
            intent = stripe.PaymentIntent.create(
                amount=int(order.total_amount * 100), # Amount in cents
                currency='npr',
                metadata={'order_id': order.id}
            )
            return Response({
                'clientSecret': intent['client_secret']
            })
        except Exception as e:
            return Response({'error': str(e)}, status=400)

    @action(detail=True, methods=['post'], url_path='initiate-khalti-payment')
    def initiate_khalti(self, request, pk=None):
        order = self.get_object()
        url = "https://a.khalti.com/api/v2/epayment/initiate/"
        
        return_url = request.data.get('return_url', 'kissanconnect://payment-success')
        
        payload = {
            "return_url": return_url,
            "website_url": "https://kissanconnect.com",
            "amount": int(order.total_amount * 100), # Paisa
            "purchase_order_id": str(order.id),
            "purchase_order_name": f"Order #{order.id}",
        }
        
        headers = {
            'Authorization': f'Key {os.environ.get("KHALTI_SECRET_KEY")}',
            'Content-Type': 'application/json',
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            return Response(response.json(), status=response.status_code)
        except Exception as e:
            return Response({'error': str(e)}, status=400)

    @action(detail=True, methods=['post'], url_path='verify-khalti-payment')
    def verify_khalti(self, request, pk=None):
        order = self.get_object()
        pidx = request.data.get('pidx')
        
        url = "https://a.khalti.com/api/v2/epayment/lookup/"
        payload = {"pidx": pidx}
        headers = {
            'Authorization': f'Key {os.environ.get("KHALTI_SECRET_KEY")}',
            'Content-Type': 'application/json',
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            data = response.json()
            
            if data.get('status') == 'Completed':
                order.status = 'paid'
                order.transaction_id = pidx
                order.save()
                return Response({'status': 'success', 'message': 'Payment successful'})
            else:
                return Response({'status': 'failed', 'message': data.get('status', 'Unknown error')}, status=400)
        except Exception as e:
            return Response({'error': str(e)}, status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def stripe_webhook(request):
    payload = request.body
    sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
    endpoint_secret = os.environ.get('STRIPE_WEBHOOK_SECRET')

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except Exception as e:
        return Response({'error': str(e)}, status=400)

    if event['type'] == 'payment_intent.succeeded':
        intent = event['data']['object']
        order_id = intent['metadata'].get('order_id')
        if order_id:
            try:
                order = Order.objects.get(id=order_id)
                order.status = 'paid'
                order.transaction_id = intent['id']
                order.save()
            except Order.DoesNotExist:
                pass

    return Response({'status': 'success'})
