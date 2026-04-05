from django.contrib import admin
from .models import Order, OrderItem

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
