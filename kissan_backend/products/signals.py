"""
Django signals for the products app.
Sends FCM push notifications when product approval status changes.
- Approved: seller gets confirmation + all other users get "new product" alert
- Rejected: only the seller is notified
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Product


@receiver(post_save, sender=Product)
def notify_on_approval_status_change(sender, instance, created, **kwargs):
    """
    When a product's approval_status changes to 'approved' or 'rejected',
    send push notifications accordingly.
    """
    if created:
        return  # Don't fire on initial creation (product is still pending)

    try:
        seller = instance.seller
        if not seller:
            return

        from kissan_core.firebase_helper import send_push, send_push_to_many
        import threading

        if instance.approval_status == 'approved':
            def _send():
                # 1. Notify the seller who owns the product
                send_push(
                    user=seller,
                    title='Product Approved!',
                    body=f'Your product "{instance.name}" has been approved and is now live on KissanConnect!',
                    data={'route': 'seller_dashboard'},
                )

                # 2. Notify ALL other users (buyers + other sellers) about the new product
                try:
                    from users.models import User
                    other_users = list(
                        User.objects.exclude(id=seller.id)
                    )
                    if other_users:
                        send_push_to_many(
                            users=other_users,
                            title='New Product Available!',
                            body=f'"{instance.name}" is now available on KissanConnect. Check it out!',
                            data={'route': 'home'},
                        )
                except Exception as e:
                    print(f'New product notification to users error: {e}')

            threading.Thread(target=_send).start()

        elif instance.approval_status == 'rejected':
            note = f' Reason: {instance.admin_note}' if instance.admin_note else ''

            def _send():
                send_push(
                    user=seller,
                    title='Product Rejected',
                    body=f'Your product "{instance.name}" was not approved.{note}',
                    data={'route': 'seller_dashboard'},
                )
            threading.Thread(target=_send).start()

    except Exception as e:
        print(f'Product approval signal error: {e}')
