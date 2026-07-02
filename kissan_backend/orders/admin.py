from django.contrib import admin
from .models import Order, OrderItem, Transaction

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('product', 'quantity', 'price')

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'total_amount', 'status', 'payment_gateway', 'created_at')
    list_filter = ('status', 'payment_gateway', 'created_at')
    search_fields = ('user__email', 'transaction_id', 'id')
    readonly_fields = ('user', 'total_amount', 'payment_gateway', 'transaction_id', 'created_at', 'updated_at')
    list_editable = ('status',)
    inlines = [OrderItemInline]

@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('order', 'product', 'quantity', 'price')
    list_filter = ('product__category',)

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('id', 'order', 'seller_email', 'gross_amount', 'commission_amount', 'net_payout', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('seller__email', 'order__id')
    list_editable = ('status',)
    readonly_fields = ('order', 'seller', 'gross_amount', 'commission_amount', 'net_payout', 'created_at')
    ordering = ('-created_at',)

    def seller_email(self, obj):
        return obj.seller.email
    seller_email.short_description = 'Seller Email'
