import base64
from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.conf import settings
from .models import Product
from .serializers import (
    ProductSerializer,
    ProductRegistrationSerializer,
    ProductMatchRequestSerializer
)
from vision.services import VisionService
from accounts.permissions import IsShopOwner, IsActiveShopMember

def get_catalog_owner(user):
    """
    Returns the user who owns the inventory:
    - If user is SHOP_OWNER -> self
    - If user is SHOP_WORKER -> assigned shop's owner
    """
    if getattr(user, 'role', None) == 'SHOP_OWNER':
        return user
    elif getattr(user, 'role', None) == 'SHOP_WORKER' and user.is_worker_active and user.assigned_shop:
        return user.assigned_shop.owner
    return None


class ProductListCreateView(generics.ListCreateAPIView):
    """
    GET /api/products/
    Returns the active shop inventory for the owner or assigned worker.
    
    POST /api/products/register/
    Registers a new product (UNIT or KG) under the authenticated shop owner.
    Workers are strictly forbidden (403).
    """
    permission_classes = (permissions.IsAuthenticated, IsActiveShopMember)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ProductRegistrationSerializer
        return ProductSerializer

    def get_queryset(self):
        owner = get_catalog_owner(self.request.user)
        if not owner:
            return Product.objects.none()
        return Product.objects.filter(user=owner).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        if request.user.role != 'SHOP_OWNER':
            return Response(
                {'detail': 'Workers are not authorized to add products or modify inventory.'},
                status=status.HTTP_403_FORBIDDEN
            )
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        product = serializer.save()
        return Response(ProductSerializer(product, context={'request': request}).data, status=status.HTTP_201_CREATED)


class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET, PUT, PATCH, DELETE /api/products/<int:pk>/
    - GET: Available to Shop Owner and active assigned Shop Workers.
    - PUT, PATCH, DELETE: Restricted strictly to Shop Owner.
    """
    serializer_class = ProductSerializer
    permission_classes = (permissions.IsAuthenticated, IsActiveShopMember)

    def get_queryset(self):
        owner = get_catalog_owner(self.request.user)
        if not owner:
            return Product.objects.none()
        return Product.objects.filter(user=owner)

    def update(self, request, *args, **kwargs):
        if request.user.role != 'SHOP_OWNER':
            return Response(
                {'detail': 'Workers are not authorized to edit product details or stock.'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'SHOP_OWNER':
            return Response(
                {'detail': 'Workers are not authorized to delete products.'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)


class ProductMatchView(APIView):
    """
    POST /api/products/match/
    Visual item recognition endpoint:
    - Performs cosine similarity against the shop's registered catalog.
    - Available to both Owner and active Workers on duty.
    """
    permission_classes = (permissions.IsAuthenticated, IsActiveShopMember)

    def post(self, request, *args, **kwargs):
        serializer = ProductMatchRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        cam_url = data.get('esp32_cam_url') or getattr(settings, 'DEFAULT_ESP32_STREAM_URL', 'http://192.168.1.100:81/stream')
        capture_from_esp32 = data.get('capture_from_esp32', False)
        image_base64 = data.get('image_base64')
        uploaded_file = request.FILES.get('image')
        threshold = data.get('similarity_threshold', getattr(settings, 'CV_SIMILARITY_THRESHOLD', 0.78))

        # Obtain the raw image bytes
        image_bytes = None
        if uploaded_file:
            image_bytes = uploaded_file.read()
        elif image_base64:
            try:
                if ',' in image_base64:
                    image_base64 = image_base64.split(',', 1)[1]
                image_bytes = base64.b64decode(image_base64)
            except Exception as e:
                return Response({'error': f'Invalid base64 image: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        elif capture_from_esp32 or cam_url:
            image_bytes, err = VisionService.capture_frame_from_esp32(cam_url)
            if err or not image_bytes:
                return Response(
                    {'error': f'Failed to capture frame from ESP32-CAM ({cam_url}): {err}'},
                    status=status.HTTP_502_BAD_GATEWAY
                )
        else:
            return Response(
                {'error': 'Provide either an uploaded image file, base64 string, or enable capture_from_esp32.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        owner = get_catalog_owner(request.user)
        if not owner:
            return Response({'error': 'No active shop catalog available for your account.'}, status=status.HTTP_400_BAD_REQUEST)

        # Delegate to vision matching engine strictly for this shop's catalog
        match_result = VisionService.match_product(
            user=owner,
            image_bytes=image_bytes,
            similarity_threshold=threshold
        )

        return Response(match_result, status=status.HTTP_200_OK)
