"""
Django signals for the products app.
Sends FCM push notifications to sellers when their product approval status changes.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Product


@receiver(post_save, sender=Product)
def notify_seller_on_approval(sender, instance, created, **kwargs):
    """
    When a product's approval_status changes to 'approved' or 'rejected',
    send a push notification to the seller.
    """
    if created:
        return  # Don't fire on initial creation

    try:
        seller = instance.seller
        if not seller or not seller.fcm_token:
            return

        from kissan_core.firebase_helper import send_push
        import threading

        if instance.approval_status == 'approved':
            def _send():
                send_push(
                    token=seller.fcm_token,
                    title='✅ Product Approved!',
                    body=f'Your product "{instance.name}" has been approved and is now live on KissanConnect!',
                    data={'route': 'seller_dashboard'},
                )
            threading.Thread(target=_send).start()

        elif instance.approval_status == 'rejected':
            note = f' Reason: {instance.admin_note}' if instance.admin_note else ''
            def _send():
                send_push(
                    token=seller.fcm_token,
                    title='❌ Product Rejected',
                    body=f'Your product "{instance.name}" was not approved.{note}',
                    data={'route': 'seller_dashboard'},
                )
            threading.Thread(target=_send).start()

    except Exception as e:
        print(f'Product approval signal error: {e}')
