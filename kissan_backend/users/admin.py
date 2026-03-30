from django.contrib import admin
from .models import User, EmailOTP

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('email', 'full_name', 'phone_number', 'is_verified', 'is_staff', 'date_joined')
    search_fields = ('email', 'full_name', 'phone_number')
    list_filter = ('is_verified', 'is_staff')

@admin.register(EmailOTP)
class EmailOTPAdmin(admin.ModelAdmin):
    list_display = ('email', 'otp', 'validated', 'created_at')
    search_fields = ('email',)
    list_filter = ('validated',)
