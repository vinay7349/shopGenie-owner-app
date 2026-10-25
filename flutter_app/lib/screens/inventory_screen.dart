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
  final Set<int> _expandedProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadAdjustmentsForProduct(int productId) async {
    if (!mounted) return;
    setState(() => _isLoadingAdjustments = true);
    try {
      final adjustments = await widget.apiService.getStockAdjustments();
      if (mounted) {
        setState(() {
          _adjustments = adjustments;
          _isLoadingAdjustments = false;
          _expandedProductIds.add(productId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdjustments = false);
      }
    }
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
                        value: 'PIECE',
                        decoration: const InputDecoration(labelText: 'Unit*'),
                        items: ['PIECE', 'KG', 'GRAM', 'LITER']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: 'DRAFT',
                        decoration: const InputDecoration(labelText: 'Status*'),
                        items: ['DRAFT', 'PUBLISHED', 'ARCHIVED']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(),
                  decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {},
              child: const Text('Create Product'),
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
                  controller: TextEditingController(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity Change (positive to add, negative to remove)*',
                    hintText: 'e.g., 10 or -5',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: 'RESTOCK',
                  decoration: const InputDecoration(labelText: 'Reason*'),
                  items: [
                    ('RESTOCK', 'Restock'),
                    ('CORRECTION', 'Correction'),
                    ('DAMAGE', 'Damage'),
                    ('OTHER', 'Other'),
                  ].map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
                  onChanged: (val) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {},
              child: const Text('Submit Adjustment'),
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
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
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
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: 'all',
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
                        onChanged: (val) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(child: Text('Inventory Screen - Implementation in progress')),
          ),
        ],
      ),
    );
  }
}