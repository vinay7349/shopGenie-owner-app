from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import Shop

User = get_user_model()

class ShopSerializer(serializers.ModelSerializer):
    owner_username = serializers.CharField(source='owner.username', read_only=True)
    worker_count = serializers.SerializerMethodField()

    class Meta:
        model = Shop
        fields = (
            'id', 'name', 'address', 'category', 'phone',
            'business_hours', 'description', 'verification_status',
            'is_active', 'rating', 'owner_username', 'worker_count',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'owner_username', 'worker_count', 'created_at', 'updated_at')

    def get_worker_count(self, obj):
        return obj.workers.filter(is_worker_active=True).count()


class WorkerSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'is_worker_active', 'can_view_invoices', 'can_confirm_bills',
            'date_joined'
        )
        read_only_fields = ('id', 'date_joined')


class WorkerCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'password', 'can_view_invoices', 'can_confirm_bills'
        )

    def create(self, validated_data):
        owner = self.context['request'].user
        shop = getattr(owner, 'owned_shop', None)
        if not shop:
            raise serializers.ValidationError("Owner does not have an active shop.")

        password = validated_data.pop('password')
        worker = User(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=User.Role.SHOP_WORKER,
            assigned_shop=shop,
            is_worker_active=True,
            can_view_invoices=validated_data.get('can_view_invoices', True),
            can_confirm_bills=validated_data.get('can_confirm_bills', True)
        )
        worker.set_password(password)
        worker.save()
        return worker


class WorkerUpdateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = (
            'first_name', 'last_name', 'is_worker_active',
            'can_view_invoices', 'can_confirm_bills', 'password'
        )

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        if password:
            instance.set_password(password)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class UserSerializer(serializers.ModelSerializer):
    shop = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'role', 'shop',
            'is_worker_active', 'can_view_invoices', 'can_confirm_bills',
            'date_joined'
        )
        read_only_fields = ('id', 'role', 'date_joined')

    def get_shop(self, obj):
        shop = obj.effective_shop
        if shop:
            return ShopSerializer(shop).data
        return None


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        help_text="Confirmation password"
    )

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'shop_name', 'password', 'password2')
        extra_kwargs = {
            'email': {'required': True}
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        shop_name = validated_data.get('shop_name', '').strip() or f"{validated_data['username']}'s Shop"
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            shop_name=shop_name,
            role=User.Role.SHOP_OWNER
        )
        # Automatically provision the single shop for the new owner
        Shop.objects.create(
            owner=user,
            name=shop_name,
            category='Grocery & Supermarket',
            verification_status='VERIFIED'
        )
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Enhanced JWT token serializer returning user role, shop information, and permissions.
    Enforces active worker status at login time.
    """
    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user

        # If user is a worker, verify their active status
        if user.role == User.Role.SHOP_WORKER and not user.is_worker_active:
            raise serializers.ValidationError({
                "detail": "Your worker account has been deactivated by the shop owner."
            })

        shop = user.effective_shop
        data['user'] = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'role': user.role,
            'shop_name': shop.name if shop else user.shop_name,
            'is_worker_active': user.is_worker_active,
            'can_view_invoices': user.can_view_invoices,
            'can_confirm_bills': user.can_confirm_bills,
            'shop': ShopSerializer(shop).data if shop else None,
        }
        return data
