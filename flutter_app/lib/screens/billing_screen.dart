import 'package:flutter/material.dart';
import '../models.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'invoice_history_screen.dart';

class BillingScreen extends StatefulWidget {
  final ApiService apiService;
  final bool isOwner;

  const BillingScreen({
    super.key,
    required this.apiService,
    required this.isOwner,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Product> _products = [];
  List<InvoiceItem> _billItems = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _pendingIdempotencyKey = '';
  bool _isSubmitting = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await widget.apiService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final query = _searchQuery.toLowerCase();
    return _products.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query) ||
        p.brand.toLowerCase().contains(query)).toList();
  }

  void _addToBill(Product product) {
    setState(() {
      final existingIndex = _billItems.indexWhere((i) => i.product.id == product.id);
      if (existingIndex >= 0) {
        _billItems[existingIndex].quantity += 1.0;
      } else {
        _billItems.add(InvoiceItem(
          product: product,
          quantity: 1.0,
          price: product.sellingPrice,
        ));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${product.name} to bill'), duration: const Duration(milliseconds: 800)),
    );
  }

  void _removeFromBill(int index) {
    setState(() {
      _billItems.removeAt(index);
    });
  }

  double get _billTotal {
    return _billItems.fold<double>(0.0, (acc, item) => acc + item.total);
  }

  String _generateIdempotencyKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _confirmBill() async {
    if (_billItems.isEmpty) return;

    // If we have a pending idempotency key from a previous attempt, ask user
    String idempotencyKey;
    if (_pendingIdempotencyKey.isNotEmpty) {
      final useExisting = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Retry Previous Bill?'),
          content: const Text('A previous bill submission is pending. Use the same idempotency key to safely retry, or generate a new one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('New Key'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Retry with Same Key'),
            ),
          ],
        ),
      );
      idempotencyKey = useExisting == true ? _pendingIdempotencyKey : _generateIdempotencyKey();
    } else {
      idempotencyKey = _generateIdempotencyKey();
    }

    _pendingIdempotencyKey = idempotencyKey;
    setState(() => _isSubmitting = true);

    try {
      final res = await widget.apiService.confirmBill(
        items: _billItems,
        idempotencyKey: idempotencyKey,
      );
      if (mounted) {
        final invId = res['id']?.toString() ?? 'UNKNOWN';
        _pendingIdempotencyKey = '';
        _billItems.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice #$invId created successfully!'), backgroundColor: AppTheme.successGreen),
        );
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Bill Confirmed!'),
              ],
            ),
            content: Text('Invoice #$invId for ₹${_billTotal.toStringAsFixed(2)} created successfully!\n\nInventory stock was automatically deducted.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        String userMsg;
        if (errStr.contains('409')) {
          userMsg = 'This bill was already submitted with a different content. Please generate a new bill.';
        } else if (errStr.contains('Insufficient stock')) {
          userMsg = 'One or more items have insufficient stock. Please refresh and try again.';
        } else if (errStr.contains('not available') || errStr.contains('not found')) {
          userMsg = 'Some products are no longer available. Please refresh products and try again.';
        } else if (errStr.contains('SocketException') || errStr.contains('Connection refused') || errStr.contains('timeout')) {
          userMsg = 'Network error. The bill may have been processed. Check invoice history or retry with the same key.';
        } else {
          userMsg = 'Bill submission failed: $errStr';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMsg), backgroundColor: AppTheme.errorRed, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearBill() {
    setState(() {
      _billItems.clear();
      _pendingIdempotencyKey = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Products',
            onPressed: _loadProducts,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Invoice History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InvoiceHistoryScreen(apiService: widget.apiService)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search Item name or category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Product List
          Expanded(
            child: _buildProductList(),
          ),

          // Bill Summary Footer
          if (_billItems.isNotEmpty) _buildBillSummary(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_error != null && _products.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to Load Products',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadProducts,
      );
    }

    if (_filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: _searchQuery.isNotEmpty ? 'No Matching Products' : 'No Products Available',
        message: _searchQuery.isNotEmpty
            ? 'Try a different search term or clear the search.'
            : 'Add products in the Inventory tab to start billing.',
        actionLabel: _searchQuery.isNotEmpty ? 'Clear Search' : 'Refresh',
        onAction: _searchQuery.isNotEmpty ? () => setState(() => _searchQuery = '') : _loadProducts,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final product = _filteredProducts[idx];
        final inStock = product.stockQuantity > 0;
        final inBillIndex = _billItems.indexWhere((i) => i.product.id == product.id);
        final billQty = inBillIndex >= 0 ? _billItems[inBillIndex].quantity : 0.0;

        return ListTile(
          title: Text(
            product.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: inStock ? null : Colors.grey,
            ),
          ),
          subtitle: Text(
            '₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit} • Stock: ${product.stockQuantity.toStringAsFixed(product.unit == 'PIECE' ? 0 : 3)}',
            style: TextStyle(color: inStock ? null : Colors.grey),
          ),
          trailing: inStock
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (billQty > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen),
                        ),
                        child: Text(
                          'In Bill: ${billQty.toStringAsFixed(product.unit == 'PIECE' ? 0 : 3)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _addToBill(product),
                    ),
                  ],
                )
              : const Chip(
                  label: Text('OUT OF STOCK', style: TextStyle(fontSize: 10)),
                  backgroundColor: AppTheme.errorLight,
                ),
        );
      },
    );
  }

  Widget _buildBillSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_lastError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_lastError!, style: const TextStyle(color: AppTheme.errorRed))),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items: ${_billItems.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Total: ₹${_billTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Clear Bill',
                    onPressed: _clearBill,
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Bill'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _billItems.isEmpty || _isSubmitting ? null : _confirmBill,
                  ),
                ],
              ),
            ],
          ),
          if (_billItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Note: Server uses current selling prices and validates stock. Bill total shown is an estimate; final total is server-authoritative.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}