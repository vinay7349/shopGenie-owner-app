import 'package:flutter/material.dart';
import '../../models.dart';
import '../../api_service.dart';
import '../../theme/app_theme.dart';
import '../../../widgets.dart';

class OwnerDashboardScreen extends StatelessWidget {
  final ApiService apiService;
  final User user;
  final void Function(int) onNavigate;

  const OwnerDashboardScreen({
    super.key,
    required this.apiService,
    required this.user,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return OwnerDashboardView(
      apiService: apiService,
      user: user,
      onNavigate: onNavigate,
    );
  }
}

class OwnerDashboardView extends StatefulWidget {
  final ApiService apiService;
  final User user;
  final void Function(int) onNavigate;

  const OwnerDashboardView({
    super.key,
    required this.apiService,
    required this.user,
    required this.onNavigate,
  });

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  DashboardData? _dashboard;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await widget.apiService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesStr = _dashboard != null ? '₹${_dashboard!.todaySales.toStringAsFixed(0)}' : '—';
    final billsStr = _dashboard != null ? '${_dashboard!.todayInvoices}' : '—';
    final totalProdStr = _dashboard != null ? '${_dashboard!.totalProducts}' : '—';
    final lowStockStr = _dashboard != null ? '${_dashboard!.lowStockProducts}' : '—';
    final totalSalesStr = _dashboard != null ? '₹${_dashboard!.totalSales.toStringAsFixed(0)}' : '—';
    final totalInvoicesStr = _dashboard != null ? '${_dashboard!.totalInvoices}' : '—';
    final availableProductsStr = _dashboard != null ? '${_dashboard!.availableProducts}' : '—';
    final activeOffersStr = _dashboard != null ? '${_dashboard!.activeOffers}' : '—';
    final activeWorkersStr = _dashboard != null ? '${_dashboard!.activeWorkers}' : '—';

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Overview Section
          _buildBusinessOverview(
            totalSalesStr,
            totalInvoicesStr,
            totalProdStr,
            availableProductsStr,
            activeOffersStr,
            activeWorkersStr,
          ),
          const SizedBox(height: 16),
          
          // Today's Performance Section
          SGCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today\'s Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (_isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricCol('Today Sales', salesStr, Icons.currency_rupee),
                    _metricCol('Bills', _dashboard != null ? '${_dashboard!.todayInvoices}' : '—', Icons.receipt_long),
                    _metricCol('Low Stock', lowStockStr, Icons.warning_amber_rounded, color: AppTheme.amberWarning),
                  ],
                ),
                if (_dashboard != null && _dashboard!.lowStockProducts > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.amberLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.amberWarning),
                        const SizedBox(width: 6),
                        Text(
                          '${_dashboard!.lowStockProducts} products running low on stock!',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Operations Section
          const Text('Quick Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _quickActionCard('Start Billing', Icons.qr_code_scanner, () => widget.onNavigate(1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard('Inventory', Icons.inventory_2_outlined, () => widget.onNavigate(2)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard('Manage Workers', Icons.people_outline, () => widget.onNavigate(5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard('Offers & News', Icons.campaign_outlined, () => widget.onNavigate(3)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard('My Shop', Icons.store_outlined, () => widget.onNavigate(6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard('Invoices', Icons.receipt_long, () => widget.onNavigate(7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessOverview(
    String totalSales,
    String totalInvoices,
    String totalProducts,
    String availableProducts,
    String activeOffers,
    String activeWorkers,
  ) {
    return SGCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _overviewCard('Total Sales', '₹', 'Total revenue all time', Icons.currency_rupee, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _overviewCard('Total Invoices', '', 'Total completed invoices', Icons.receipt_long, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _overviewCard('Total Products', '', 'All products in catalog', Icons.inventory_2, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _overviewCard('Available', '', 'Products published & in stock', Icons.check_circle, Colors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _overviewCard('Active Offers', '', 'Currently running promotions', Icons.local_offer, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _overviewCard('Active Workers', '', 'Staff with active status', Icons.people, Colors.indigo)),
            ],
          ),
          const SizedBox(height: 16),
          // Metrics not available from backend
          const Divider(),
          const SizedBox(height: 8),
          const Text('Advanced Metrics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _notAvailableCard('Gross Profit', 'Requires cost price tracking per invoice')),
              const SizedBox(width: 12),
              Expanded(child: _notAvailableCard('Stock Valuation', 'Requires cost price × current stock')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewCard(String title, String prefix, String subtitle, IconData icon, Color color) {
    return SGCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title == 'Total Sales' ? '₹0' : '0',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _notAvailableCard(String title, String reason) {
    return SGCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block_rounded, size: 20, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Not available',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
          const SizedBox(height: 4),
          Text(reason, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _metricCol(String title, String val, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey[700]),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _quickActionCard(String title, IconData icon, VoidCallback onTap) {
    return SGCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppTheme.primaryGreen),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}