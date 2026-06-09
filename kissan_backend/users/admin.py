from django.contrib import admin
from .models import User, EmailOTP, SellerProfile
from unfold.admin import ModelAdmin

@admin.register(User)
class UserAdmin(ModelAdmin):
    list_display = ('email', 'full_name', 'role', 'is_seller_verified', 'is_verified', 'is_staff', 'date_joined')
    search_fields = ('email', 'full_name', 'phone_number')
    list_filter = ('role', 'is_seller_verified', 'is_verified', 'is_staff')
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('full_name', 'phone_number')}),
        ('Permissions', {'fields': ('role', 'is_seller_verified', 'is_active', 'is_staff', 'is_superuser')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )

@admin.register(EmailOTP)
class EmailOTPAdmin(ModelAdmin):
    list_display = ('email', 'otp', 'validated', 'created_at')
    search_fields = ('email',)
    list_filter = ('validated',)

@admin.register(SellerProfile)
class SellerProfileAdmin(ModelAdmin):
    list_display = ('shop_name', 'user', 'payout_gateway', 'status', 'created_at')
    list_filter = ('status', 'payout_gateway')
    search_fields = ('shop_name', 'user__email')
    list_editable = ('status',)
    
    # Protecting seller data: Admin can only change the "Status"
    readonly_fields = (
        'user', 'shop_name', 'shop_description', 'shop_address', 
        'PAN_NUMBER', 'citizenship_front', 'citizenship_back', 
        'payout_gateway', 'payout_id', 'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('Business Information', {
            'fields': ('user', 'shop_name', 'shop_description', 'shop_address', 'status')
        }),
        ('Verification Documents', {
            'fields': ('PAN_NUMBER', 'citizenship_front', 'citizenship_back')
        }),
        ('Payout Details', {
            'fields': ('payout_gateway', 'payout_id')
        }),
    )
