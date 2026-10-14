from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import transaction
from django.db.models import Sum, F, Count
from decimal import Decimal
from .models import Invoice, InvoiceItem
from .serializers import (
    InvoiceSerializer,
    InvoiceItemSerializer,
    CheckoutAcceptSerializer
)
from products.models import Product
from products.views import get_catalog_owner
from accounts.permissions import (
    IsShopOwner,
    IsActiveShopMember,
    CanViewInvoicesPermission,
    CanConfirmBillsPermission
)

class CheckoutAcceptView(APIView):
    """
    POST /api/checkout/accept/
    Processes an authenticated stock reduction and checkout item billing.
    
    Guarantees:
    1. Transactional atomicity (transaction.atomic).
    2. Concurrency-safe row locking via select_for_update() to prevent race-condition overselling.
    3. Strict backend calculation of item price and invoice total (never trusts client amount).
    4. Supports UNIT (whole integer) and KG (fractional decimal).
    5. Role & Permission check: Owner or active Worker with can_confirm_bills permission.
    """
    permission_classes = (permissions.IsAuthenticated, CanConfirmBillsPermission)

    def post(self, request, *args, **kwargs):
        serializer = CheckoutAcceptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        product_id = serializer.validated_data['product_id']
        requested_qty = Decimal(str(serializer.validated_data['quantity']))
        invoice_id = serializer.validated_data.get('invoice_id')

        owner = get_catalog_owner(request.user)
        if not owner:
            return Response({'error': 'No active shop catalog found.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                # Lock the product row for update to prevent concurrent checkout race conditions
                try:
                    product = Product.objects.select_for_update().get(
                        id=product_id,
                        user=owner
                    )
                except Product.DoesNotExist:
                    return Response(
                        {'error': 'Product not found or does not belong to your shop catalog.'},
                        status=status.HTTP_404_NOT_FOUND
                    )

                # Validate UNIT vs KG quantity semantics
                if product.selling_type == Product.SellingType.UNIT:
                    if requested_qty % 1 != 0:
                        return Response(
                            {'error': f'Product "{product.name}" is sold by UNIT and requires an integer quantity.'},
                            status=status.HTTP_400_BAD_REQUEST
                        )

                # Validate stock availability
                if product.quantity < requested_qty:
                    return Response(
                        {
                            'error': f'Insufficient stock for "{product.name}". Available: {product.formatted_quantity}, Requested: {requested_qty}',
                            'available_quantity': product.quantity,
                            'requested_quantity': requested_qty,
                        },
                        status=status.HTTP_409_CONFLICT
                    )

                # Atomically decrement stock
                product.quantity = (product.quantity - requested_qty).quantize(Decimal('0.001'))
                product.save(update_fields=['quantity', 'updated_at'])

                # Find existing invoice or create a new invoice under the shop owner
                if invoice_id:
                    try:
                        invoice = Invoice.objects.select_for_update().get(id=invoice_id, user=owner)
                    except Invoice.DoesNotExist:
                        invoice = Invoice.objects.create(user=owner, status=Invoice.Status.COMPLETED)
                else:
                    invoice = Invoice.objects.create(user=owner, status=Invoice.Status.COMPLETED)

                # Calculate item total strictly on backend: total_price = quantity * price_per_unit
                unit_price = product.price_per_unit
                item_total = (requested_qty * unit_price).quantize(Decimal('0.01'))

                # Create or aggregate line item
                existing_item = invoice.items.filter(product=product).first()
                if existing_item:
                    existing_item.quantity = (existing_item.quantity + requested_qty).quantize(Decimal('0.001'))
                    existing_item.total_price = (existing_item.quantity * existing_item.unit_price).quantize(Decimal('0.01'))
                    existing_item.save(update_fields=['quantity', 'total_price'])
                    invoice_item = existing_item
                else:
                    invoice_item = InvoiceItem.objects.create(
                        invoice=invoice,
                        product=product,
                        quantity=requested_qty,
                        unit_price=unit_price,
                        total_price=item_total
                    )

                # Recalculate invoice overall total
                invoice.recalculate_total()

                return Response({
                    'message': 'Checkout item accepted successfully.',
                    'invoice': InvoiceSerializer(invoice).data,
                    'billed_item': InvoiceItemSerializer(invoice_item).data,
                    'remaining_stock': {
                        'product_id': product.id,
                        'product_name': product.name,
                        'quantity': product.quantity,
                        'formatted_quantity': product.formatted_quantity,
                    }
                }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {'error': f'Checkout transaction failed: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class InvoiceListView(generics.ListAPIView):
    """
    GET /api/checkout/invoices/
    Returns list of invoices for the shop.
    Workers must have can_view_invoices permission.
    """
    serializer_class = InvoiceSerializer
    permission_classes = (permissions.IsAuthenticated, CanViewInvoicesPermission)

    def get_queryset(self):
        owner = get_catalog_owner(self.request.user)
        if not owner:
            return Invoice.objects.none()
        return Invoice.objects.filter(user=owner).prefetch_related('items__product').order_by('-created_at')


class InvoiceDetailView(generics.RetrieveAPIView):
    """
    GET /api/checkout/invoices/<id>/
    Retrieves full details of an invoice.
    Workers must have can_view_invoices permission.
    """
    serializer_class = InvoiceSerializer
    permission_classes = (permissions.IsAuthenticated, CanViewInvoicesPermission)

    def get_queryset(self):
        owner = get_catalog_owner(self.request.user)
        if not owner:
            return Invoice.objects.none()
        return Invoice.objects.filter(user=owner).prefetch_related('items__product')


class AnalyticsView(APIView):
    """
    GET /api/checkout/analytics/
    Computes business metrics for the shopkeeper dashboard:
    - Total Revenue
    - Total Profit (Selling Price - Cost Price)
    - Total Inventory Valuation (at cost & retail)
    - Low-Stock alerts (stock < 5 units or < 2 kg)
    
    Strictly restricted to Shop Owners (403 for workers).
    """
    permission_classes = (permissions.IsAuthenticated, IsShopOwner)

    def get(self, request, *args, **kwargs):
        owner = request.user
        products = Product.objects.filter(user=owner)
        invoices = Invoice.objects.filter(user=owner, status=Invoice.Status.COMPLETED)

        total_revenue = invoices.aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')

        # Calculate estimated total profit from line items
        line_items = InvoiceItem.objects.filter(invoice__user=owner, invoice__status=Invoice.Status.COMPLETED)
        total_cost = sum(
            (item.quantity * item.product.cost_price for item in line_items.select_related('product')),
            Decimal('0.00')
        )
        total_profit = max(Decimal('0.00'), total_revenue - total_cost)

        # Inventory valuation
        valuation_cost = sum((p.quantity * p.cost_price for p in products), Decimal('0.00'))
        valuation_retail = sum((p.quantity * p.price_per_unit for p in products), Decimal('0.00'))

        # Low-stock detection (UNIT < 5 or KG < 2.0)
        low_stock_products = []
        for p in products:
            if (p.selling_type == Product.SellingType.UNIT and p.quantity < 5) or \
               (p.selling_type == Product.SellingType.KG and p.quantity < 2):
                low_stock_products.append({
                    'id': p.id,
                    'name': p.name,
                    'selling_type': p.selling_type,
                    'quantity': float(p.quantity),
                    'formatted_quantity': p.formatted_quantity
                })

        return Response({
            'total_revenue': float(total_revenue),
            'total_profit': float(total_profit),
            'inventory_valuation_cost': float(valuation_cost),
            'inventory_valuation_retail': float(valuation_retail),
            'total_products_count': products.count(),
            'total_invoices_count': invoices.count(),
            'low_stock_count': len(low_stock_products),
            'low_stock_items': low_stock_products,
        }, status=status.HTTP_200_OK)
