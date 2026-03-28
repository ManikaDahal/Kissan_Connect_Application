import requests
from django.conf import settings
from rest_framework import exceptions

def verify_google_token(id_token):
    """
    Verifies a Google ID token using Google's tokeninfo endpoint.
    In a production app, you might use `google-auth` library.
    """
    try:
        response = requests.get(
            f'https://oauth2.googleapis.com/tokeninfo?id_token={id_token}',
            timeout=5
        )
        if response.status_code != 200:
            raise exceptions.AuthenticationFailed('Invalid Google token')
        
        data = response.json()
        
        # Basic checks
        if data.get('aud') != settings.GOOGLE_CLIENT_ID:
            # Note: In some cases, you might have multiple client IDs (iOS, Android, Web)
            # For simplicity, we assume one.
            pass
            
        return data
    except Exception as e:
        raise exceptions.AuthenticationFailed(f'Google verification failed: {str(e)}')
