import 'package:flutter/material.dart';
import '../models/analytics.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../ui_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  ShopAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await AuthService().getCurrentUser();
      final analytics = await InvoiceService().getAnalytics();

      if (!mounted) return;
      setState(() {
        _user = user;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = _user?.shopName ?? 'Kirana Store';
    final username = _user?.username ?? 'Shopkeeper';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE POS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Merchant: @$username',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.apps_outlined),
            tooltip: 'UI Preview',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UiPreviewScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile & Settings',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppTheme.primaryGreen,
        child: _isLoading
            ? const LoadingStateView(message: 'Loading store dashboard...')
            : _error != null
                ? ErrorStateView(
                    message: _error!,
                    onRetry: _loadDashboardData,
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HosaFlow-Inspired Hero Banner: AI Scanner
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, '/scan'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF004D36),
                                  Color(0xFF006C4C),
                                  Color(0xFF00895E),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                                  blurRadius = 12,
                                  offset = const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF8CF4C5),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'SMART VISION POS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.auto_awesome, color: Color(0xFFFFDDB3), size: 22),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'AI Product Checkout',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scan branded packets or plain bags with 1-tap optical recognition',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/scan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryGreen,
                                    minimumSize: const Size(140, 42),
                                    shape: RoundedCornerShape(12),
                                  ),
                                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                  label: const Text('Start AI Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Analytics Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Retail Overview',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'Real-time',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid (2x2)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          children: [
                            StatCard(
                              title: 'Total Sales',
                              value: '₹${_analytics?.totalSales.toStringAsFixed(2) ?? '0.00'}',
                              icon: Icons.currency_rupee,
                              iconColor: AppTheme.primaryGreen,
                              trendText: 'Today',
                            ),
                            StatCard(
                              title: 'Gross Profit',
                              value: '₹${_analytics?.totalProfit.toStringAsFixed(2) ?? '0.00'}',
                              icon: Icons.trending_up,
                              iconColor: const Color(0xFF16A34A),
                              trendText: '+Margin',
                            ),
                            StatCard(
                              title: 'Stock Valuation',
                              value: '₹${_analytics?.inventoryValuationRetail.toStringAsFixed(0) ?? '0'}',
                              subtitle: 'Retail Value',
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: const Color(0xFF0284C7),
                              onTap: () => Navigator.pushNamed(context, '/inventory'),
                            ),
                            StatCard(
                              title: 'Invoices Paid',
                              value: '${_analytics?.totalInvoices ?? 0}',
                              subtitle: '${_analytics?.totalProducts ?? 0} SKUs catalog',
                              icon: Icons.receipt_long_outlined,
                              iconColor: const Color(0xFF7C3AED),
                              onTap: () => Navigator.pushNamed(context, '/invoices'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Low Stock Alert Banner
                        if (_analytics != null && _analytics!.lowStockCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFDE68A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_analytics!.lowStockCount} Items Low in Stock',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reorder soon to avoid running out of top selling commodities.',
                                        style: TextStyle(fontSize: 12, color: Colors.brown[700]),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/inventory'),
                                  child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Store Operations & Shortcuts
                        const Text(
                          'Store Operations',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _ModernActionTile(
                                label: 'POS Billing',
                                subtitle: 'Cashier checkout',
                                icon: Icons.point_of_sale_outlined,
                                color: AppTheme.primaryGreen,
                                bg: const Color(0xFFD1FAE5),
                                onTap: () => Navigator.pushNamed(context, '/billing'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModernActionTile(
                                label: 'Loose Scale',
                                subtitle: 'Sugar, Dal & Grains',
                                icon: Icons.scale_outlined,
                                color: const Color(0xFFD97706),
                                bg: const Color(0xFFFFE0B2),
                                onTap: () => Navigator.pushNamed(context, '/manual_selection'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ModernActionTile(
                                label: 'Catalog & Stock',
                                subtitle: 'Manage all products',
                                icon: Icons.inventory_2_outlined,
                                color: const Color(0xFF0284C7),
                                bg: const Color(0xFFE0F2FE),
                                onTap: () => Navigator.pushNamed(context, '/products'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModernActionTile(
                                label: 'Invoice History',
                                subtitle: 'Past receipts & bills',
                                icon: Icons.receipt_long_outlined,
                                color: const Color(0xFF7C3AED),
                                bg: const Color(0xFFEDE9FE),
                                onTap: () => Navigator.pushNamed(context, '/invoices'),
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

class _ModernActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ModernActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
