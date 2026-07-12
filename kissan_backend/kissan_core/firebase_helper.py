"""
Firebase Admin SDK helper for sending FCM push notifications.
Initialized lazily the first time send_push() is called.
"""
import os
import json
import firebase_admin
from firebase_admin import credentials, messaging

_initialized = False


def _init():
    global _initialized
    if _initialized:
        return
    # Try loading from a JSON file (local dev) or from env var (Hugging Face)
    sa_path = os.path.join(os.path.dirname(__file__), '..', 'firebase-service-account.json')
    sa_path = os.path.normpath(sa_path)

    if os.path.exists(sa_path):
        cred = credentials.Certificate(sa_path)
    else:
        # On Hugging Face, store the entire JSON content in FIREBASE_SA_JSON env var
        sa_json = os.environ.get('FIREBASE_SA_JSON')
        if not sa_json:
            print("WARNING: Firebase service account not configured. Push notifications disabled.")
            return
        cred = credentials.Certificate(json.loads(sa_json))

    firebase_admin.initialize_app(cred)
    _initialized = True


def send_push(token: str, title: str, body: str, data: dict = None):
    """
    Send a single FCM push notification to a device token.
    Silently fails if Firebase is not configured.
    """
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
            token=token,
        )
        messaging.send(message)
    except Exception as e:
        print(f"FCM send_push error: {e}")


def send_push_to_many(tokens: list, title: str, body: str, data: dict = None):
    """
    Send the same push notification to a list of device tokens (batch).
    """
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
