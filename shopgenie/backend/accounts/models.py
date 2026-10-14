from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from django.conf import settings
from django.core.exceptions import ValidationError

class Shop(models.Model):
    """
    Shop entity strictly bound to exactly one Shop Owner (One-to-One).
    Workers belong to this shop via assigned_shop.
    """
    owner = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='owned_shop',
        help_text="The single authenticated Shop Owner who owns and manages this shop."
    )
    name = models.CharField(max_length=200, db_index=True)
    address = models.TextField(blank=True, default='')
    category = models.CharField(max_length=100, default='Grocery & Supermarket')
    phone = models.CharField(max_length=30, blank=True, default='')
    business_hours = models.CharField(max_length=100, default='08:00 AM - 10:00 PM (Daily)')
    description = models.TextField(blank=True, default='Neighbourhood retail storefront powered by ShopGenie POS.')
    verification_status = models.CharField(
        max_length=30,
        default='VERIFIED',
        choices=[
            ('VERIFIED', 'Verified'),
            ('UNDER_REVIEW', 'Under Review'),
            ('PENDING', 'Pending Verification'),
            ('REJECTED', 'Rejected'),
        ]
    )
    is_active = models.BooleanField(default=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=4.80)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'shopgenie_shops'
        verbose_name = 'Shop'
        verbose_name_plural = 'Shops'

    def __str__(self):
        return f"{self.name} (Owner: {self.owner.username})"


class CustomUser(AbstractUser):
    """
    Custom User model representing either a Shop Owner or an assigned Shop Worker.
    Role is strictly backend-enforced.
    """
    class Role(models.TextChoices):
        SHOP_OWNER = 'SHOP_OWNER', 'Shop Owner'
        SHOP_WORKER = 'SHOP_WORKER', 'Shop Worker'

    email = models.EmailField(unique=True, db_index=True)
    shop_name = models.CharField(max_length=150, blank=True, default='')
    date_joined = models.DateTimeField(default=timezone.now)

    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.SHOP_OWNER,
        db_index=True,
        help_text="Backend-enforced user role: SHOP_OWNER or SHOP_WORKER."
    )
    assigned_shop = models.ForeignKey(
        Shop,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='workers',
        help_text="The shop this worker is assigned to. Only valid for SHOP_WORKER."
    )
    is_worker_active = models.BooleanField(
        default=True,
        help_text="Allows the owner to deactivate worker accounts immediately without deleting records."
    )

    # Worker Permission Flags
    can_view_invoices = models.BooleanField(
        default=True,
        help_text="Permission for worker to view invoice history."
    )
    can_confirm_bills = models.BooleanField(
        default=True,
        help_text="Permission for worker to accept checkout items and complete bills."
    )

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    class Meta:
        db_table = 'shopgenie_users'
        verbose_name = 'Shopkeeper / Worker User'
        verbose_name_plural = 'Shopkeeper / Worker Users'

    @property
    def is_owner(self):
        return self.role == self.Role.SHOP_OWNER

    @property
    def is_worker(self):
        return self.role == self.Role.SHOP_WORKER

    @property
    def effective_shop(self):
        """Returns the shop associated with this user, whether as owner or worker."""
        if self.role == self.Role.SHOP_OWNER:
            return getattr(self, 'owned_shop', None)
        elif self.role == self.Role.SHOP_WORKER and self.is_worker_active:
            return self.assigned_shop
        return None

    def clean(self):
        super().clean()
        if self.role == self.Role.SHOP_WORKER and hasattr(self, 'owned_shop'):
            raise ValidationError({'role': 'A worker cannot own a shop.'})
        if self.role == self.Role.SHOP_OWNER and self.assigned_shop is not None:
            raise ValidationError({'assigned_shop': 'A shop owner cannot be assigned as a worker to another shop.'})

    def __str__(self):
        return f"{self.username} [{self.role}] ({self.email})"
