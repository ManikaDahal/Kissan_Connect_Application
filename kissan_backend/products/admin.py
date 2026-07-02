from django.contrib import admin
from django.utils import timezone
from .models import Category, Product, Review, CategorySuggestion

@admin.register(CategorySuggestion)
class CategorySuggestionAdmin(admin.ModelAdmin):
    list_display = ('name', 'seller', 'status', 'created_at', 'reviewed_at')
    list_filter = ('status', 'created_at')
    search_fields = ('name', 'seller__email', 'seller__full_name', 'reason')
    actions = ['approve_suggestions', 'reject_suggestions']

    def approve_suggestions(self, request, queryset):
        approved_count = 0
        for suggestion in queryset.filter(status='pending'):
            # create category
            Category.objects.get_or_create(name=suggestion.name)
            # update suggestion status
            suggestion.status = 'approved'
            suggestion.reviewed_at = timezone.now()
            if not suggestion.admin_note:
                suggestion.admin_note = "Approved by admin."
            suggestion.save()
            approved_count += 1
        self.message_user(request, f"{approved_count} suggestions approved and categories created.")
    approve_suggestions.short_description = "Approve and create categories"

    def reject_suggestions(self, request, queryset):
        rejected_count = 0
        for suggestion in queryset.filter(status='pending'):
            suggestion.status = 'rejected'
            suggestion.reviewed_at = timezone.now()
            if not suggestion.admin_note:
                suggestion.admin_note = "Rejected by admin."
            suggestion.save()
            rejected_count += 1
        self.message_user(request, f"{rejected_count} suggestions rejected.")
    reject_suggestions.short_description = "Reject suggestions"

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_at')
    search_fields = ('name',)

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'seller', 'category', 'price', 'stock', 'weight', 'unit_type', 'is_famous', 'created_at')
    search_fields = ('name', 'description', 'seller__email')
    list_filter = ('category', 'is_famous', 'seller')
    list_editable = ('is_famous', 'stock', 'weight', 'unit_type')

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('user', 'product', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('product__name', 'user__full_name', 'comment')
