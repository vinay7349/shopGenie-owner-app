import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'ALL';

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

        final matchesCategory = _selectedCategory == 'ALL' ||
            (_selectedCategory == 'UNIT' && !product.isKg) ||
            (_selectedCategory == 'KG' && product.isKg) ||
            (_selectedCategory == 'LOOSE' && product.isLoose) ||
            product.category.toUpperCase() == _selectedCategory.toUpperCase();

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.pushNamed(
      context,
      '/product_detail',
      arguments: product,
    );
    _loadProducts();
  }

  Future<void> _addProduct() async {
    final result = await Navigator.pushNamed(
      context,
      '/add_product',
    );
    if (result != null) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product Catalog'),
            Text(
              '${_products.length} Items in inventory',
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
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: AppTheme.primaryGreen,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products by name or category...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'All (${_products.length})',
                    isSelected: _selectedCategory == 'ALL',
                    onSelected: () {
                      _selectedCategory = 'ALL';
                      _filterProducts();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Packaged (Unit)',
                    isSelected: _selectedCategory == 'UNIT',
                    onSelected: () {
                      _selectedCategory = 'UNIT';
                      _filterProducts();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'By Weight (Kg)',
                    isSelected: _selectedCategory == 'KG',
                    onSelected: () {
                      _selectedCategory = 'KG';
                      _filterProducts();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Loose Bags',
                    isSelected: _selectedCategory == 'LOOSE',
                    onSelected: () {
                      _selectedCategory = 'LOOSE';
                      _filterProducts();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Products List
            Expanded(
              child: _isLoading
                  ? const LoadingStateView(message: 'Loading catalog products...')
                  : _errorMessage != null
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _loadProducts,
                        )
                      : _filteredProducts.isEmpty
                          ? EmptyStateView(
                              icon: Icons.inventory_2_outlined,
                              title: 'No Products Found',
                              description: _searchController.text.isNotEmpty
                                  ? 'No items match "${_searchController.text}".'
                                  : 'Add your first product to catalog stock.',
                              actionLabel: 'Add First Product',
                              onAction: _addProduct,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                              itemCount: _filteredProducts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _ModernProductCard(
                                  product: product,
                                  onTap: () => _openProduct(product),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      label: Text(label),
      selectedColor: const Color(0xFFD1FAE5),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

class _ModernProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ModernProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unit = product.isKg ? 'kg' : 'unit';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  product.isKg || product.isLoose ? Icons.scale_outlined : Icons.inventory_2_outlined,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SellingTypeBadge(
                          sellingType: product.sellingType,
                          isLoose: product.isLoose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${product.pricePerUnit.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              TextSpan(
                                text: ' / $unit',
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
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}