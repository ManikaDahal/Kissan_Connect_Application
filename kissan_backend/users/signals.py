from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from .models import SellerProfile
import threading

@receiver(pre_save, sender=SellerProfile)
def track_seller_status_change(sender, instance, **kwargs):
    if instance.pk:
        try:
            old_profile = SellerProfile.objects.get(pk=instance.pk)
            instance._old_status = old_profile.status
        except SellerProfile.DoesNotExist:
            instance._old_status = None
    else:
        instance._old_status = None

@receiver(post_save, sender=SellerProfile)
def notify_on_seller_status_change(sender, instance, created, **kwargs):
    if created:
        return

    old_status = getattr(instance, '_old_status', None)
    if old_status == instance.status:
        return

    try:
        from kissan_core.firebase_helper import send_push
        
        if instance.status == 'approved':
            def _send():
                send_push(
                    user=instance.user,
                    title='Seller Account Approved!',
                    body='Congratulations! Your seller account has been approved. You can now start adding products.',
                    data={'route': 'seller_dashboard'},
                )
            threading.Thread(target=_send).start()

        elif instance.status == 'rejected':
            def _send():
                send_push(
                    user=instance.user,
                    title='Seller Account Rejected',
                    body='Unfortunately, your seller application was not approved. Please contact support for more details.',
                    data={'route': 'home'},
                )
            threading.Thread(target=_send).start()

    except Exception as e:
        print(f'Seller status signal error: {e}')
