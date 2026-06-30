import stripe
import os
import requests
from decimal import Decimal
from django.conf import settings
from rest_framework import viewsets, permissions, status, views
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from .models import Order, OrderItem, Transaction
from .serializers import OrderSerializer
from products.models import Product
from users.models import UserAddress

stripe.api_key = os.environ.get('STRIPE_SECRET_KEY')


COMMISSION_RATE = Decimal('0.05')  # 5% platform commission


def _deduct_stock(order):
    """Deducts stock for each item in the order after successful payment."""
    for item in order.items.select_related('product').all():
        if item.product:
            item.product.stock = max(0, item.product.stock - item.quantity)
            item.product.save()


def _create_seller_transactions(order):
    """Creates Transaction records for each seller involved in this order.
    Groups items by seller, calculates 5% commission, and records a 'held' payout."""
    # Group items by seller
    seller_totals = {}
    for item in order.items.select_related('product__seller').all():
        if not item.product or not item.product.seller:
            continue
        seller = item.product.seller
        gross = item.price * item.quantity
        seller_totals[seller] = seller_totals.get(seller, 0) + gross

    # Create one Transaction record per seller
    for seller, gross_amount in seller_totals.items():
        commission = round(gross_amount * COMMISSION_RATE, 2)
        net_payout = round(gross_amount - commission, 2)
        Transaction.objects.get_or_create(
            order=order,
            seller=seller,
            defaults={
                'gross_amount': gross_amount,
                'commission_amount': commission,
                'net_payout': net_payout,
                'status': 'held',
            }
        )


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

                #  Stock validation — reject order if not enough stock
                if product.stock < qty:
                    return Response(
                        {'error': f"Not enough stock for '{product.name}'. Only {product.stock} left."},
                        status=status.HTTP_400_BAD_REQUEST
                    )

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
            payment_gateway=request.data.get('payment_gateway', 'cod'),
            shipping_address=UserAddress.objects.filter(id=request.data.get('shipping_address_id')).first() if request.data.get('shipping_address_id') else None
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
                amount=int(order.total_amount * 100),  # Amount in cents
                currency='npr',
                metadata={'order_id': order.id}
            )
            return Response({
                'clientSecret': intent['client_secret']
            })
        except Exception as e:
            # Mark order as failed so it doesn't stay as ghost "pending"
            order.status = 'failed'
            order.save()
            return Response({'error': str(e)}, status=400)

    @action(detail=True, methods=['post'], url_path='initiate-khalti-payment')
    def initiate_khalti(self, request, pk=None):
        order = self.get_object()
        url = "https://a.khalti.com/api/v2/epayment/initiate/"

        return_url = request.data.get('return_url', 'kissanconnect://payment-success')

        payload = {
            "return_url": return_url,
            "website_url": "https://kissanconnect.com",
            "amount": int(order.total_amount * 100),  # Paisa
            "purchase_order_id": str(order.id),
            "purchase_order_name": f"Order #{order.id}",
        }

        headers = {
            'Authorization': f'Key {os.environ.get("KHALTI_SECRET_KEY")}',
            'Content-Type': 'application/json',
        }

        try:
            response = requests.post(url, json=payload, headers=headers)
            if response.status_code != 200:
                # Mark order as failed if Khalti rejects the request
                order.status = 'failed'
                order.save()
            return Response(response.json(), status=response.status_code)
        except Exception as e:
            order.status = 'failed'
            order.save()
            return Response({'error': str(e)}, status=400)

    @action(detail=True, methods=['post'], url_path='cancel')
    def cancel_order(self, request, pk=None):
        """Called by the Flutter app when a user cancels or payment fails on their end."""
        order = self.get_object()
        if order.status == 'pending':
            order.status = 'failed'
            order.save()
        return Response({'status': order.status})

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
                if order.status != 'paid':  # Prevent double deduction
                    order.status = 'paid'
                    order.transaction_id = pidx
                    order.save()
                    _deduct_stock(order)
                    _create_seller_transactions(order)
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
                if order.status != 'paid':  # Prevent double deduction
                    order.status = 'paid'
                    order.transaction_id = intent['id']
                    order.save()
                    _deduct_stock(order)
                    _create_seller_transactions(order)
            except Order.DoesNotExist:
                pass
    elif event['type'] in ['payment_intent.payment_failed', 'payment_intent.canceled']:
        intent = event['data']['object']
        order_id = intent['metadata'].get('order_id')
        if order_id:
            try:
                order = Order.objects.get(id=order_id)
                if order.status == 'pending':
                    order.status = 'failed'
                    order.save()
            except Order.DoesNotExist:
                pass

    return Response({'status': 'success'})


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def seller_orders(request):
    """Returns all orders that contain products belonging to the logged-in seller."""
    from .models import OrderItem

    # Find all order items where the product belongs to this seller
    seller_items = OrderItem.objects.filter(
        product__seller=request.user
    ).select_related('order', 'order__user', 'order__shipping_address', 'product')

    # Group by order to avoid duplicates
    orders_dict = {}
    for item in seller_items:
        order = item.order
        if order.id not in orders_dict:
            orders_dict[order.id] = {
                'id': order.id,
                'buyer_email': order.user.email,
                'buyer_name': order.user.full_name,
                'status': order.status,
                'payment_gateway': order.payment_gateway,
                'total_amount': str(order.total_amount),
                'created_at': order.created_at.isoformat(),
                'shipping_address': {
                    'full_name': order.shipping_address.full_name if order.shipping_address else 'N/A',
                    'city': order.shipping_address.city if order.shipping_address else 'N/A',
                    'area': order.shipping_address.area if order.shipping_address else 'N/A',
                    'province': order.shipping_address.province if order.shipping_address else 'N/A',
                    'phone_number': order.shipping_address.phone_number if order.shipping_address else 'N/A',
                } if order.shipping_address else None,
                'my_items': [],
            }
        # Only add items that belong to this seller
        orders_dict[order.id]['my_items'].append({
            'item_id': item.id,
            'product_name': item.product.name if item.product else 'Deleted Product',
            'quantity': item.quantity,
            'price': str(item.price),
            'item_status': item.status,
        })

    orders_list = sorted(orders_dict.values(), key=lambda x: x['created_at'], reverse=True)
    return Response(orders_list)


@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def update_item_status(request, item_id):
    """Allows a seller to update the delivery status of their own OrderItem.
    When marked 'delivered', automatically releases the associated Transaction funds."""
    try:
        item = OrderItem.objects.select_related('product__seller', 'order').get(id=item_id)
    except OrderItem.DoesNotExist:
        return Response({'error': 'Item not found'}, status=404)

    # Security: only the seller who owns the product can update its status
    if not item.product or item.product.seller != request.user:
        return Response({'error': 'Permission denied'}, status=403)

    new_status = request.data.get('status')
    valid = [choice[0] for choice in OrderItem.STATUS_CHOICES]
    if new_status not in valid:
        return Response({'error': f'Invalid status. Choose from: {valid}'}, status=400)

    item.status = new_status
    item.save()

    # When seller marks item delivered, release the held transaction funds
    if new_status == 'delivered':
        Transaction.objects.filter(
            order=item.order,
            seller=request.user,
            status='held'
        ).update(status='released')

    return Response({'success': True, 'item_id': item.id, 'new_status': item.status})
