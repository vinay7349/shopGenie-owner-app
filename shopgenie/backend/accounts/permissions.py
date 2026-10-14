from rest_framework import permissions

class IsShopOwner(permissions.BasePermission):
    """
    Allows access only to authenticated users who are SHOP_OWNER.
    """
    message = "Only authorized Shop Owners can access or modify this resource."

    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and
            user.is_authenticated and
            getattr(user, 'role', None) == 'SHOP_OWNER'
        )


class IsActiveShopMember(permissions.BasePermission):
    """
    Allows access to either the Shop Owner or an active Shop Worker.
    """
    message = "Account is inactive or not authorized to access this shop's data."

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if user.role == 'SHOP_OWNER':
            return True
        if user.role == 'SHOP_WORKER':
            return bool(user.is_worker_active and user.assigned_shop_id)
        return False


class CanViewInvoicesPermission(permissions.BasePermission):
    """
    Allows access to view invoices:
    - Shop Owners always have access.
    - Workers only if is_worker_active and can_view_invoices is True.
    """
    message = "You do not have permission to view invoice history."

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if user.role == 'SHOP_OWNER':
            return True
        if user.role == 'SHOP_WORKER':
            return bool(user.is_worker_active and user.can_view_invoices)
        return False


class CanConfirmBillsPermission(permissions.BasePermission):
    """
    Allows access to bill items:
    - Shop Owners always have access.
    - Workers only if is_worker_active and can_confirm_bills is True.
    """
    message = "You do not have permission to confirm bills or accept checkout items."

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if user.role == 'SHOP_OWNER':
            return True
        if user.role == 'SHOP_WORKER':
            return bool(user.is_worker_active and user.can_confirm_bills)
        return False
