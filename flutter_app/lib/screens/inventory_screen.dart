import 'package:flutter/material.dart';
import '../models.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class InventoryScreen extends StatefulWidget {
  final ApiService apiService;
  final bool isOwner;
  final User currentUser;

  const InventoryScreen({
    super.key,
    required this.apiService,
    required this.isOwner,
    required this.currentUser,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  List<StockAdjustment> _adjustments = [];
  bool _isLoading = false;
  bool _isLoadingAdjustments = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

  Future<void> _loadAdjustments() async {
    if (!mounted) return;
    setState(() => _isLoadingAdjustments = true);
    try {
      final adjustments = await widget.apiService.getStockAdjustments();
      if (mounted) {
        setState(() {
          _adjustments = adjustments;
          _isLoadingAdjustments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdjustments = false);
      }
    }
  }

  List<Product> get _filteredProducts {
    var result = _products;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.id.toString().contains(query)).toList();
    }
    if (_filterStatus != 'all') {
      result = result.where((p) => p.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
    }
    return result;
  }

  void _showAddProductDialog() {
    final nameCtl = TextEditingController();
    final categoryCtl = TextEditingController(text: 'General');
    final brandCtl = TextEditingController();
    final sizeCtl = TextEditingController();
    final descriptionCtl = TextEditingController();
    final mrpCtl = TextEditingController();
    final sellingPriceCtl = TextEditingController();
    final costPriceCtl = TextEditingController();
    final stockCtl = TextEditingController(text: '0');
    final imageUrlCtl = TextEditingController();
    String selectedUnit = 'PIECE';
    String selectedStatus = 'DRAFT';
    bool isSubmitting = false;
    String? dialogError;

    const units = ['PIECE', 'KG', 'GRAM', 'LITER'];
    const statuses = ['DRAFT', 'PUBLISHED', 'ARCHIVED'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(dialogError!, style: const TextStyle(color: AppTheme.errorRed)),
                  ),
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Product Name*'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandCtl,
                  decoration: const InputDecoration(labelText: 'Brand (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sizeCtl,
                  decoration: const InputDecoration(labelText: 'Size (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: mrpCtl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'MRP*'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceCtl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Selling Price*'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costPriceCtl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cost Price*'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockCtl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Initial Stock*'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit*'),
                        items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setDialogState(() => selectedUnit = val ?? 'PIECE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status*'),
                        items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setDialogState(() => selectedStatus = val ?? 'DRAFT'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrlCtl,
                  decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtl.text.trim().isEmpty) {
                        setDialogState(() => dialogError = 'Product name is required');
                        return;
                      }
                      final mrp = double.tryParse(mrpCtl.text.trim());
                      final sellingPrice = double.tryParse(sellingPriceCtl.text.trim());
                      final costPrice = double.tryParse(costPriceCtl.text.trim());
                      final stock = double.tryParse(stockCtl.text.trim());
                      if (mrp == null || sellingPrice == null || costPrice == null || stock == null) {
                        setDialogState(() => dialogError = 'All price and stock fields must be valid numbers');
                        return;
                      }
                      if (sellingPrice > mrp) {
                        setDialogState(() => dialogError = 'Selling price cannot exceed MRP');
                        return;
                      }
                      if (costPrice > sellingPrice) {
                        setDialogState(() => dialogError = 'Cost price cannot exceed selling price');
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await widget.apiService.createProduct({
                          'shop': widget.currentUser.shop!.id,
                          'name': nameCtl.text.trim(),
                          'category': categoryCtl.text.trim(),
                          'brand': brandCtl.text.trim(),
                          'size': sizeCtl.text.trim(),
                          'description': descriptionCtl.text.trim(),
                          'mrp': mrp.toString(),
                          'selling_price': sellingPrice.toString(),
                          'cost_price': costPrice.toString(),
                          'stock_quantity': stock.toString(),
                          'unit': selectedUnit,
                          'image_url': imageUrlCtl.text.trim(),
                          'status': selectedStatus,
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = e.toString().replaceFirst('ApiException: ', '');
                          });
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustStockDialog(Product product) {
    final quantityCtl = TextEditingController();
    final noteCtl = TextEditingController();
    String selectedReason = 'RESTOCK';
    bool isSubmitting = false;
    String? dialogError;

    const reasons = [
      ('RESTOCK', 'Restock'),
      ('CORRECTION', 'Correction'),
      ('DAMAGE', 'Damage'),
      ('OTHER', 'Other'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock: ${product.stockQuantity.toStringAsFixed(product.unit == 'PIECE' ? 0 : 3)} ${product.unit}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (dialogError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(dialogError!, style: const TextStyle(color: AppTheme.errorRed)),
                  ),
                TextField(
                  controller: quantityCtl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity Change (positive to add, negative to remove)*',
                    hintText: 'e.g., 10 or -5',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(labelText: 'Reason*'),
                  items: reasons.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
                  onChanged: (val) => setDialogState(() => selectedReason = val ?? 'RESTOCK'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final qtyText = quantityCtl.text.trim();
                      if (qtyText.isEmpty) {
                        setDialogState(() => dialogError = 'Quantity change is required');
                        return;
                      }
                      final delta = double.tryParse(qtyText);
                      if (delta == null) {
                        setDialogState(() => dialogError = 'Invalid quantity');
                        return;
                      }
                      if (delta == 0) {
                        setDialogState(() => dialogError = 'Quantity change cannot be zero');
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await widget.apiService.createStockAdjustment(
                          productId: product.id,
                          delta: delta,
                          reason: selectedReason,
                          note: noteCtl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                          _loadAdjustments();
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = e.toString().replaceFirst('ApiException: ', '');
                          });
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Adjustment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'PUBLISHED', child: Text('Published')),
                          DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                          DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                        ],
                        onChanged: (val) => setState(() => _filterStatus = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                      onPressed: _loadAdjustments,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _buildProductList(),
          ),
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
        title: 'Failed to Load Inventory',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadData,
      );
    }

    if (_filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: _searchQuery.isNotEmpty ? 'No Matching Products' : 'No Products Yet',
        message: _searchQuery.isNotEmpty
            ? 'Try a different search term or clear the filter.'
            : 'Add products to start managing your inventory.',
        actionLabel: _searchQuery.isNotEmpty ? 'Clear Search' : 'Add Product',
        onAction: _searchQuery.isNotEmpty ? () => setState(() => _searchQuery = '') : _showAddProductDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredProducts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final productAdjustments = _adjustments.where((a) => a.product == product.id).toList();
          final isLowStock = product.stockQuantity <= 5;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _productIcon(product),
                      ),
                    )
                  : _productIcon(product),
              title: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLowStock ? AppTheme.amberWarning : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${product.category} • ${product.unit}'),
                  Text(
                    'Stock: ${product.stockQuantity.toStringAsFixed(product.unit == 'PIECE' ? 0 : 3)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isLowStock ? AppTheme.amberWarning : Colors.green,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.amberLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LOW STOCK',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.amberWarning),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (widget.isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                      tooltip: 'Adjust Stock',
                      onPressed: () => _showAdjustStockDialog(product),
                    ),
                ],
              ),
              children: [
                if (productAdjustments.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adjustment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...productAdjustments.take(10).map((adj) => _adjustmentTile(adj)),
                        if (productAdjustments.length > 10)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Showing 10 of ${productAdjustments.length} adjustments',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (_isLoadingAdjustments)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No adjustment history yet', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _productIcon(Product product) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.paleMint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.inventory_2, color: AppTheme.primaryGreen, size: 24),
    );
  }

  Widget _adjustmentTile(StockAdjustment adj) {
    final isPositive = adj.delta > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? AppTheme.successLight : AppTheme.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPositive ? AppTheme.successGreen : AppTheme.errorRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                adj.reason,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${adj.delta.toStringAsFixed(3)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
            ],
          ),
          if (adj.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(adj.note, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(adj.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}