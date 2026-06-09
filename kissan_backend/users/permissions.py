from rest_framework import permissions

class IsSeller(permissions.BasePermission):
    """
    Allows access only to verified sellers.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and 
            request.user.is_authenticated and 
            request.user.role == 'seller' and 
            request.user.is_seller_verified
        )

class IsProductOwner(permissions.BasePermission):
    """
    Allows access only to the owner of the product.
    """
    def has_object_permission(self, request, view, obj):
        # Allow read-only permissions to any request
        if request.method in permissions.SAFE_METHODS:
            return True
        # Write permissions only to the seller of the product
        return obj.seller == request.user
