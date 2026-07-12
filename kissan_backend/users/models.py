from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils import timezone
from datetime import timedelta


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email address is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractUser):
    username = None
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, unique=True, null=True, blank=True)
    ROLE_CHOICES = [
        ('buyer', 'Buyer'),
        ('seller', 'Seller'),
        ('admin', 'Admin'),
    ]
    
    full_name = models.CharField(max_length=100, blank=True)
    is_verified = models.BooleanField(default=False)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='buyer')
    is_seller_verified = models.BooleanField(default=False)
    fcm_token = models.CharField(max_length=512, blank=True, null=True,
                                 help_text="Firebase Cloud Messaging device token for push notifications")

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    objects = UserManager()

    def __str__(self):
        return self.email


class EmailOTP(models.Model):
    """Stores OTPs for email verification and password reset."""
    email = models.EmailField()
    otp = models.CharField(max_length=6)
    purpose = models.CharField(
        max_length=20,
        choices=[('signup', 'Signup'), ('reset', 'Password Reset')],
        default='signup'
    )
    count = models.IntegerField(default=0)
    validated = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def is_expired(self):
        """OTP expires after 10 minutes."""
        return timezone.now() > self.updated_at + timedelta(minutes=10)

    def __str__(self):
        return f"{self.email} [{self.purpose}] - {self.otp}"


class UserAddress(models.Model):
    PROVINCE_CHOICES = [
        ('Koshi', 'Koshi Province'),
        ('Madhesh', 'Madhesh Province'),
        ('Bagmati', 'Bagmati Province'),
        ('Gandaki', 'Gandaki Province'),
        ('Lumbini', 'Lumbini Province'),
        ('Karnali', 'Karnali Province'),
        ('Sudurpashchim', 'Sudurpashchim Province'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    full_name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    province = models.CharField(max_length=50, choices=PROVINCE_CHOICES)
    city = models.CharField(max_length=100)
    area = models.CharField(max_length=100)
    house_no = models.CharField(max_length=50, blank=True, null=True)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "User Addresses"

    def __str__(self):
        return f"{self.full_name} - {self.city}, {self.province}"


class SellerProfile(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='seller_profile')
    shop_name = models.CharField(max_length=150)
    shop_description = models.TextField(blank=True)
    shop_address = models.TextField()
    citizenship_front = models.ImageField(upload_to='seller_docs/', null=True, blank=True)
    citizenship_back = models.ImageField(upload_to='seller_docs/', null=True, blank=True)
    PAN_NUMBER = models.CharField(max_length=20, blank=True, null=True)
    
    # Payout Details (eSewa/Stripe for College Project)
    PAYMENT_GATEWAY_CHOICES = [
        ('esewa', 'eSewa'),
        ('stripe', 'Stripe'),
    ]
    payout_gateway = models.CharField(max_length=20, choices=PAYMENT_GATEWAY_CHOICES, default='esewa')
    payout_id = models.CharField(max_length=150, help_text="eSewa ID (Phone) or Stripe Account ID")
    
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        # Automatically update user role and verification when profile is approved
        if self.status == 'approved':
            self.user.role = 'seller'
            self.user.is_seller_verified = True
            self.user.save()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.shop_name} ({self.user.email})"


class SupportTicket(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='support_tickets')
    message = models.TextField()
    is_resolved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Ticket #{self.id} from {self.user.email}"
