from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from .models import Shop
from .serializers import (
    RegisterSerializer,
    UserSerializer,
    CustomTokenObtainPairSerializer,
    ShopSerializer,
    WorkerSerializer,
    WorkerCreateSerializer,
    WorkerUpdateSerializer,
)
from .permissions import IsShopOwner

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    """
    POST /api/auth/register/
    Registers a new shopkeeper account, creates their single shop, and returns JWT credentials.
    """
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate JWT tokens for instant onboarding
        refresh = RefreshToken.for_user(user)

        return Response({
            'message': 'Account registered successfully.',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)


class CustomLoginView(TokenObtainPairView):
    """
    POST /api/auth/login/
    Authenticates shopkeeper or worker credentials and issues role-aware JWT tokens.
    """
    permission_classes = (permissions.AllowAny,)
    serializer_class = CustomTokenObtainPairSerializer


class CustomTokenRefreshView(TokenRefreshView):
    """
    POST /api/auth/refresh/
    Refreshes an expired JWT access token using a valid refresh token.
    """
    permission_classes = (permissions.AllowAny,)


class UserProfileView(generics.RetrieveAPIView):
    """
    GET /api/auth/me/
    Retrieves the authenticated user's profile with role, shop details, and permissions.
    """
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        return self.request.user


class MyShopView(APIView):
    """
    GET, PUT, PATCH, POST /api/auth/my-shop/
    Enforces the Single-Shop Rule:
    - Exactly one active shop per Shop Owner.
    - Workers are forbidden.
    - Owner can view and update permitted shop details.
    - If the owner has no shop yet, POST allows initial shop setup.
    """
    permission_classes = (permissions.IsAuthenticated, IsShopOwner)

    def get(self, request):
        shop = getattr(request.user, 'owned_shop', None)
        if not shop:
            return Response(
                {'detail': 'No shop found for this owner. Please set up your shop.'},
                status=status.HTTP_404_NOT_FOUND
            )
        return Response(ShopSerializer(shop).data)

    def post(self, request):
        if hasattr(request.user, 'owned_shop'):
            return Response(
                {'detail': 'You already own an active shop. Multi-shop ownership is not permitted.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        serializer = ShopSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        shop = serializer.save(owner=request.user)
        return Response(ShopSerializer(shop).data, status=status.HTTP_201_CREATED)

    def patch(self, request):
        shop = getattr(request.user, 'owned_shop', None)
        if not shop:
            return Response({'detail': 'Shop not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = ShopSerializer(shop, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        updated_shop = serializer.save()
        return Response(ShopSerializer(updated_shop).data)

    def put(self, request):
        return self.patch(request)


class WorkerListCreateView(generics.ListCreateAPIView):
    """
    GET, POST /api/auth/workers/
    Manage workers assigned to the authenticated owner's single shop.
    - Only Shop Owners can access.
    - Worker accounts are securely created without exposing plain-text passwords.
    """
    permission_classes = (permissions.IsAuthenticated, IsShopOwner)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return WorkerCreateSerializer
        return WorkerSerializer

    def get_queryset(self):
        shop = getattr(self.request.user, 'owned_shop', None)
        if not shop:
            return User.objects.none()
        return User.objects.filter(role=User.Role.SHOP_WORKER, assigned_shop=shop).order_by('-date_joined')

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        worker = serializer.save()
        return Response(WorkerSerializer(worker).data, status=status.HTTP_201_CREATED)


class WorkerDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET, PATCH, DELETE /api/auth/workers/<int:pk>/
    - View, update status (activate/deactivate), update permissions, reset credentials, or delete worker.
    - Scoped strictly to the authenticated owner's shop.
    """
    permission_classes = (permissions.IsAuthenticated, IsShopOwner)

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return WorkerUpdateSerializer
        return WorkerSerializer

    def get_queryset(self):
        shop = getattr(self.request.user, 'owned_shop', None)
        if not shop:
            return User.objects.none()
        return User.objects.filter(role=User.Role.SHOP_WORKER, assigned_shop=shop)
