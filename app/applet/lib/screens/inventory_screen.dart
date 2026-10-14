import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _stockFilter = 'ALL'; // ALL, LOW, GOOD

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });

      _filterProducts();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterProducts() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesQuery = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);

        final matchesFilter = _stockFilter == 'ALL' ||
            (_stockFilter == 'LOW' && product.quantity <= 5) ||
            (_stockFilter == 'GOOD' && product.quantity > 5);

        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  Future<void> _addProduct() async {
    final result = await Navigator.pushNamed(context, '/add_product');
    if (result != null) {
      await _loadProducts();
    }
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.pushNamed(
      context,
      '/product_detail',
      arguments: product,
    );
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _products.where((p) => p.quantity <= 5).length;
    final totalValuation = _products.fold<double>(0, (sum, p) => sum + (p.pricePerUnit * p.quantity));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventory Health'),
            Text(
              'Stock levels & reorder alerts',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add SKU', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Strip (3 KPI Cards)
              Row(
                children: [
                  Expanded(
                    child: _MiniSummaryCard(
                      title: 'Total SKUs',
                      value: '${_products.length}',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF0284C7),
                      bg: const Color(0xFFE0F2FE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniSummaryCard(
                      title: 'Low Stock',
                      value: '$lowStockCount',
                      icon: Icons.warning_amber_rounded,
                      color: lowStockCount > 0 ? const Color(0xFFD97706) : AppTheme.primaryGreen,
                      bg: lowStockCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniSummaryCard(
                      title: 'Valuation',
                      value: '₹${totalValuation.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppTheme.primaryGreen,
                      bg: const Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search inventory items...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  FilterChip(
                    selected: _stockFilter == 'ALL',
                    label: Text('All (${_products.length})'),
                    onSelected: (_) {
                      setState(() => _stockFilter = 'ALL');
                      _filterProducts();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _stockFilter == 'LOW',
                    label: Text('Low Stock ($lowStockCount)'),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(
                      color: _stockFilter == 'LOW' ? const Color(0xFFD97706) : AppTheme.textDark,
                      fontWeight: _stockFilter == 'LOW' ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _stockFilter = 'LOW');
                      _filterProducts();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _stockFilter == 'GOOD',
                    label: Text('Optimal (${_products.length - lowStockCount})'),
                    onSelected: (_) {
                      setState(() => _stockFilter = 'GOOD');
                      _filterProducts();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: LoadingStateView(message: 'Calculating stock health...'),
                )
              else if (_errorMessage != null)
                ErrorStateView(message: _errorMessage!, onRetry: _loadProducts)
              else if (_filteredProducts.isEmpty)
                EmptyStateView(
                  icon: Icons.warehouse_outlined,
                  title: 'No Inventory Items Found',
                  description: _searchController.text.isNotEmpty
                      ? 'No items match "${_searchController.text}".'
                      : 'Add catalog products to monitor stock quantities.',
                  actionLabel: 'Add Product',
                  onAction: _addProduct,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _ModernStockCard(
                      product: product,
                      onTap: () => _openProduct(product),
                    );
                  },
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _MiniSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernStockCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ModernStockCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = product.quantity <= 5;
    final double progress = (product.quantity / 50.0).clamp(0.05, 1.0);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.category} • Cost: ₹${product.costPrice.toStringAsFixed(2)} • Sell: ₹${product.pricePerUnit.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StockStatusBadge(product: product),
                ],
              ),
              const SizedBox(height: 10),

              // Stock meter progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF0F4F1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLow ? const Color(0xFFD97706) : AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available: ${product.formattedQuantity}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    isLow ? 'REORDER RECOMMENDED' : 'OPTIMAL STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLow ? const Color(0xFFD97706) : AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}