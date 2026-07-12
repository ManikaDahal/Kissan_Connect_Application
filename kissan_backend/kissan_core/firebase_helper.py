"""
Firebase Admin SDK helper for sending FCM push notifications and saving them to the database.
Initialized lazily the first time a notification is sent.
"""
import os
import json
import firebase_admin
from firebase_admin import credentials, messaging
from notifications.models import Notification

_initialized = False


def _init():
    global _initialized
    if _initialized:
        return
    sa_path = os.path.join(os.path.dirname(__file__), '..', 'firebase-service-account.json')
    sa_path = os.path.normpath(sa_path)

    if os.path.exists(sa_path):
        cred = credentials.Certificate(sa_path)
    else:
        sa_json = os.environ.get('FIREBASE_SA_JSON')
        if not sa_json:
            print("WARNING: Firebase service account not configured. Push notifications disabled.")
            return
        cred = credentials.Certificate(json.loads(sa_json))

    firebase_admin.initialize_app(cred)
    _initialized = True


def send_push(user, title: str, body: str, data: dict = None):
    """
    Save notification in database for a user and send FCM push notification to their device.
    """
    # 1. Save to Database
    try:
        route = data.get('route') if data else None
        Notification.objects.create(
            user=user,
            title=title,
            body=body,
            route=route
        )
    except Exception as e:
        print(f"Error saving notification to DB: {e}")

    # 2. Send via FCM
    if not user.fcm_token:
        return

    try:
        _init()
        if not _initialized:
            return

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id='kissan_high_importance_channel',
                    sound='default',
                ),
            ),
            token=user.fcm_token,
        )
        messaging.send(message)
    except Exception as e:
        print(f"FCM send_push error for user {user.email}: {e}")


def send_push_to_many(users, title: str, body: str, data: dict = None):
    """
    Save notification in database for a list of users, and batch send FCM notifications to their devices.
    """
    if not users:
        return

    # 1. Save to Database for each user
    try:
        route = data.get('route') if data else None
        notifications = [
            Notification(user=user, title=title, body=body, route=route)
            for user in users
        ]
        Notification.objects.bulk_create(notifications)
    except Exception as e:
        print(f"Error bulk saving notifications to DB: {e}")

    # 2. Send via FCM in batch
    tokens = [user.fcm_token for user in users if user.fcm_token]
    if not tokens:
        return

    try:
        _init()
        if not _initialized:
            return

        messages = [
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data={k: str(v) for k, v in (data or {}).items()},
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='kissan_high_importance_channel',
                        sound='default',
                    ),
                ),
                token=token,
            )
            for token in tokens
        ]
        messaging.send_each(messages)
    except Exception as e:
        print(f"FCM send_push_to_many error: {e}")
