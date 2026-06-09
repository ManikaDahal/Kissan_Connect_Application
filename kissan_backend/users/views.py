import random
import threading
from django.contrib.auth.hashers import make_password
from rest_framework import status, permissions, views, generics
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from .models import User, EmailOTP, SellerProfile
from .serializers import UserSerializer, RegisterSerializer, ChangePasswordSerializer, SellerProfileSerializer
from django.core.mail import send_mail
from django.conf import settings

def _generate_otp():
    return str(random.randint(100000, 999999))


def _get_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

def _send_email_async(subject, message, recipient_list):
    """Helper to send email via Brevo HTTP API (SMTP is blocked on cloud platforms)."""
    def send():
        try:
            import os
            import requests as http_requests
            from django.conf import settings

            # Get the API key from environment variables (Hugging Face Secrets)
            api_key = os.environ.get('BREVO_API_KEY')
            if not api_key:
                print('[ERROR] BREVO_API_KEY is not set. Cannot send email.')
                return

            to_email = recipient_list[0] if isinstance(recipient_list, list) else recipient_list
            print(f'[DEBUG] Sending email via Brevo to {to_email}')

            resp = http_requests.post(
                "https://api.brevo.com/v3/smtp/email",
                headers={
                    "api-key": api_key,
                    "Content-Type": "application/json",
                },
                json={
                    "sender": {"name": "Kissan Connect", "email": "niraulasabina08@gmail.com"},
                    "to": [{"email": to_email}],
                    "subject": subject,
                    "textContent": message,
                },
                timeout=15,
            )

            if resp.status_code in (200, 201):
                print(f'[DEBUG] Email sent successfully via Brevo to {to_email}')
            else:
                print(f'[ERROR] Brevo API error {resp.status_code}: {resp.text}')
        except Exception as e:
            print(f'[ERROR] Brevo email delivery failed for {recipient_list}: {str(e)}')

    threading.Thread(target=send).start()

#OTP
class SendOTPView(views.APIView):
    """Send an OTP to an email for signup."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required'}, status=400)

        otp = _generate_otp()
        obj, _ = EmailOTP.objects.get_or_create(email=email, purpose='signup')
        obj.otp = otp
        obj.validated = False
        obj.count += 1
        obj.save()

        # Send email in background to prevent timeout
        _send_email_async(
            'Your KissanConnect Signup OTP',
            f'Your verification code is: {otp}\nThis code will expire in 10 minutes.',
            [email]
        )
            
        return Response({'message': 'OTP sent successfully', 'otp': otp}, status=200)


class VerifyOTPView(views.APIView):
    """Verify the OTP sent for signup."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        otp = request.data.get('otp', '').strip()

        if not email or not otp:
            return Response({'error': 'Email and OTP are required'}, status=400)

        obj = EmailOTP.objects.filter(email=email, otp=otp, purpose='signup').last()
        if not obj:
            return Response({'error': 'Invalid OTP'}, status=400)
        if obj.is_expired():
            return Response({'error': 'OTP expired. Please request a new one.'}, status=400)

        obj.validated = True
        obj.save()
        return Response({'message': 'OTP verified'}, status=200)


#Signup
class RegisterView(views.APIView):
    """Register a new user with email, name and password."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        print(f'[DEBUG] Registration attempt for: {request.data.get("email")}')
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = _get_tokens(user)
            print(f'[DEBUG] User registration successful: {user.email}')
            return Response({
                'message': 'Registration successful',
                'user': UserSerializer(user).data,
                **tokens,
            }, status=201)
        print(f'[ERROR] Registration validation failed: {serializer.errors}')
        return Response(serializer.errors, status=400)


#Login
class LoginView(views.APIView):
    """Login with email + password. Returns JWT tokens."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')
        print(f'[DEBUG] Login attempt for: {email}')

        user = User.objects.filter(email=email).first()
        if user:
            print(f'[DEBUG] User found: {email}')
            if user.check_password(password):
                tokens = _get_tokens(user)
                print(f'[DEBUG] Password correct for {email}')
                return Response({
                    'message': 'Login successful',
                    'user': UserSerializer(user).data,
                    **tokens,
                }, status=200)
            else:
                print(f'[ERROR] Incorrect password for {email}')
        else:
            print(f'[ERROR] User NOT found: {email}')
        return Response({'error': 'Invalid email or password'}, status=401)


#Google Login
from .services.google_auth import verify_google_token

class GoogleLoginView(views.APIView):
    """Login/Signup with Google ID Token."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')
        if not id_token:
            return Response({'error': 'id_token is required'}, status=400)

        try:
            google_data = verify_google_token(id_token)
            email = google_data.get('email')
            name = google_data.get('name', '')
            
            user, created = User.objects.get_or_create(
                email=email,
                defaults={'full_name': name}
            )
            
            tokens = _get_tokens(user)
            return Response({
                'message': 'Login successful',
                'user': UserSerializer(user).data,
                'is_new_user': created,
                **tokens,
            }, status=200)
        except Exception as e:
            return Response({'error': str(e)}, status=400)



class BiometricTokenRefreshView(TokenRefreshView):
    """
    Accepts a refresh token (stored securely on device after password login)
    and returns a fresh access token. Used by fingerprint/biometric login.
    POST { "refresh": "<stored_refresh_token>" }
    """
    pass  # TokenRefreshView already handles everything


#Logout

class LogoutView(views.APIView):
    """Blacklist the refresh token to log out."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully'}, status=200)
        except Exception:
            return Response({'error': 'Invalid token'}, status=400)



class ForgotPasswordView(views.APIView):
    """Send OTP to email for password reset."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({'error': 'No account found with this email'}, status=404)

        otp = _generate_otp()
        obj, _ = EmailOTP.objects.get_or_create(email=email, purpose='reset')
        obj.otp = otp
        obj.validated = False
        obj.count += 1
        obj.save()

        # Send email in background to prevent timeout
        _send_email_async(
            'KissanConnect Password Reset',
            f'Your password reset code is: {otp}\nThis code will expire in 10 minutes.',
            [email]
        )
            
        return Response({'message': 'Reset OTP sent successfully', 'otp': otp}, status=200)



class VerifyResetOTPView(views.APIView):
    """Verify the OTP for password reset (does NOT reset password yet)."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        otp = request.data.get('otp', '').strip()

        obj = EmailOTP.objects.filter(email=email, otp=otp, purpose='reset').last()
        if not obj:
            return Response({'error': 'Invalid OTP'}, status=400)
        if obj.is_expired():
            return Response({'error': 'OTP expired'}, status=400)

        obj.validated = True
        obj.save()
        return Response({'message': 'OTP verified. You can now reset your password.'}, status=200)


#Reset Password

class ResetPasswordView(views.APIView):
    """Reset password after OTP has been verified."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        otp = request.data.get('otp', '').strip()
        new_password = request.data.get('new_password', '')

        if not all([email, otp, new_password]):
            return Response({'error': 'email, otp and new_password are required'}, status=400)

        obj = EmailOTP.objects.filter(
            email=email, otp=otp, purpose='reset', validated=True
        ).last()
        if not obj:
            return Response({'error': 'OTP not verified or invalid'}, status=400)
        if obj.is_expired():
            return Response({'error': 'OTP expired'}, status=400)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)

        user.set_password(new_password)
        user.save()
        obj.delete()
        return Response({'message': 'Password reset successful. Please log in.'}, status=200)


#Change Password

class ChangePasswordView(views.APIView):
    """Change password for authenticated user."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            if not user.check_password(serializer.validated_data['old_password']):
                return Response({'error': 'Old password is incorrect'}, status=400)
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({'message': 'Password changed successfully'}, status=200)
        return Response(serializer.errors, status=400)


#Profile

class ProfileView(views.APIView):
    """Get or update authenticated user's profile."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


from rest_framework import viewsets
from .serializers import AddressSerializer
from .models import UserAddress

class AddressViewSet(viewsets.ModelViewSet):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserAddress.objects.filter(user=self.request.user).order_by('-is_default', '-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SellerApplyView(views.APIView):
    """Submit or update seller registration details."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = SellerProfileSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Seller application submitted. Waiting for admin approval.',
                'profile': serializer.data
            }, status=201)
        return Response(serializer.errors, status=400)


class SellerStatusView(views.APIView):
    """Check status of seller application."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile = getattr(request.user, 'seller_profile', None)
        if not profile:
            return Response({'status': 'not_applied', 'message': 'You have not applied for a seller account.'})
        
        return Response({
            'status': profile.status,
            'is_seller_verified': request.user.is_seller_verified,
            'shop_name': profile.shop_name,
            'message': f'Your application is currently {profile.status}.'
        })
