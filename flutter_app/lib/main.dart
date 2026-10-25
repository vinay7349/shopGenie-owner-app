import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/offer_screen.dart';
import 'screens/announcement_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/worker_management_screen.dart';

void main() {
  runApp(const ShopGenieApp());
}

class ShopGenieApp extends StatefulWidget {
  final User? initialUser;
  final ApiService? apiService;

  const ShopGenieApp({
    super.key,
    this.initialUser,
    this.apiService,
  });

  @override
  State<ShopGenieApp> createState() => _ShopGenieAppState();
}

class _ShopGenieAppState extends State<ShopGenieApp> {
  late final ApiService _api;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _currentUser = widget.initialUser;
  }

  void _handleLoginSuccess(User user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout() {
    _api.setToken(null);
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopGenie Owner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _currentUser == null
          ? LoginScreen(
              apiService: _api,
              onLoginSuccess: _handleLoginSuccess,
            )
          : MainNavigationScreen(
              apiService: _api,
              initialUser: _currentUser!,
              onLogout: _handleLogout,
            ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final ApiService? apiService;
  final User initialUser;
  final VoidCallback? onLogout;

  const MainNavigationScreen({
    super.key,
    this.apiService,
    required this.initialUser,
    this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final ApiService _api;
  late User currentUser;

  // Data cache
  DashboardData? _dashboard;
  bool _isLoadingDashboard = false;

  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    currentUser = widget.initialUser!;
    _refreshAll();
  }

  void _refreshAll() {
    _loadDashboard();
    _loadProducts();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoadingDashboard = true);
    try {
      final data = await _api.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDashboard = false);
      rethrow;
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    try {
      final list = await _api.getProducts();
      if (mounted) {
        setState(() {
          _products = list;
        });
      }
    } catch (e) {
      if (mounted) rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> ownerPages = [
      _buildOwnerDashboard(),
      _buildBillingPOS(),
      InventoryScreen(apiService: _api, isOwner: true, currentUser: currentUser),
      OfferScreen(apiService: _api),
      AnnouncementScreen(apiService: _api),
      WorkerManagementScreen(apiService: _api),
      _buildMyShopScreen(),
    ];

    final List<Widget> workerPages = [
      _buildWorkerDashboard(),
      _buildBillingPOS(),
      InventoryScreen(apiService: _api, isOwner: false, currentUser: currentUser),
      _buildWorkerProfile(),
    ];

    final pages = currentUser.isOwner ? ownerPages : workerPages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentUser.shop?.name ?? 'ShopGenie',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded),
              onPressed: widget.onLogout,
            ),
          Chip(
            label: Text(
              currentUser.role,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            backgroundColor: currentUser.isOwner
                ? AppTheme.paleMint
                : Colors.blue.withValues(alpha: 0.15),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: pages[_currentIndex < pages.length ? _currentIndex : 0]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex < pages.length ? _currentIndex : 0,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: currentUser.isOwner
            ? const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard'),
                NavigationDestination(
                    icon: Icon(Icons.point_of_sale_outlined),
                    selectedIcon: Icon(Icons.point_of_sale),
                    label: 'Billing'),
                NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: 'Inventory'),
                NavigationDestination(
                    icon: Icon(Icons.local_offer_outlined),
                    selectedIcon: Icon(Icons.local_offer),
                    label: 'Offers'),
                NavigationDestination(
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign),
                    label: 'Announcements'),
                NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge),
                    label: 'Workers'),
                NavigationDestination(
                    icon: Icon(Icons.store_outlined),
                    selectedIcon: Icon(Icons.store),
                    label: 'My Shop'),
              ]
            : const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.point_of_sale_outlined),
                    selectedIcon: Icon(Icons.point_of_sale),
                    label: 'Billing'),
                NavigationDestination(
                    icon: Icon(Icons.search),
                    selectedIcon: Icon(Icons.search),
                    label: 'Catalog'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile'),
              ],
      ),
    );
  }

  // --- SHOP OWNER DASHBOARD ---
  Widget _buildOwnerDashboard() {
    final salesStr = _dashboard != null
        ? '₹${_dashboard!.todaySales.toStringAsFixed(0)}'
        : '—';
    final billsStr = _dashboard != null
        ? '${_dashboard!.todayInvoices}'
        : '—';
    final totalProdStr = _dashboard != null
        ? '${_dashboard!.totalProducts}'
        : '—';
    final lowStockStr = _dashboard != null
        ? '${_dashboard!.lowStockProducts}'
        : '—';

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today\'s Performance',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_isLoadingDashboard)
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
                      _metricCol('Bills', billsStr, Icons.receipt_long),
                      _metricCol('Products', totalProdStr, Icons.inventory_2),
                    ],
                  ),
                  if (lowStockStr != '—' && int.tryParse(lowStockStr) != null && int.parse(lowStockStr) > 0) ...[
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
                            '$lowStockStr products running low on stock!',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quick Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _quickActionCard('Start Billing', Icons.qr_code_scanner, () => setState(() => _currentIndex = 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard('Inventory', Icons.inventory_2_outlined, () => setState(() => _currentIndex = 2)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard('Manage Workers', Icons.people_outline, () => setState(() => _currentIndex = 3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard('Offers & News', Icons.campaign_outlined, () => setState(() => _currentIndex = 4)),
              ),
            ],
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // --- WORKER DASHBOARD ---
  Widget _buildWorkerDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Colors.blue.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logged in as ${currentUser.username}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Assigned to: ${currentUser.shop?.name ?? "Kirana Shop"}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Worker Permissions:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('✔ POS Billing: ENABLED'),
                const Text('✔ Product Catalog & Stock Search: ENABLED'),
                Text('✔ Invoice History Access: ${currentUser.canViewInvoices ? "ENABLED" : "RESTRICTED"}'),
                const Text('🔒 Profit Reports & Cost Prices: HIDDEN (Enforced)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => setState(() => _currentIndex = 1),
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Open Quick Billing POS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- POS BILLING SCREEN (SHARED) ---
  Widget _buildBillingPOS() {
    return BillingScreen(apiService: _api, isOwner: currentUser.isOwner);
  }


  // --- MY SHOP SCREEN ---
  Widget _buildMyShopScreen() {
    final s = currentUser.shop!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Chip(
                      label: Text(s.verificationStatus),
                      backgroundColor: AppTheme.paleMint,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s.category, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s.address.isEmpty ? 'Address not set' : s.address)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(s.phone.isEmpty ? '+91 Not Set' : s.phone),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Shop Details'),
                  onPressed: _showEditShopDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditShopDialog() {
    final nameCtl = TextEditingController(text: currentUser.shop?.name ?? '');
    final addrCtl = TextEditingController(text: currentUser.shop?.address ?? '');
    final phoneCtl = TextEditingController(text: currentUser.shop?.phone ?? '');
    final catCtl = TextEditingController(text: currentUser.shop?.category ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Shop Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Shop Name')),
            TextField(controller: catCtl, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: addrCtl, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final updated = await _api.updateMyShop({
                  'name': nameCtl.text.trim(),
                  'address': addrCtl.text.trim(),
                  'phone': phoneCtl.text.trim(),
                  'category': catCtl.text.trim(),
                });
                setState(() {
                  currentUser = User(
                    id: currentUser.id,
                    username: currentUser.username,
                    email: currentUser.email,
                    role: currentUser.role,
                    shop: updated,
                  );
                });
              } catch (_) {
                setState(() {
                  currentUser = User(
                    id: currentUser.id,
                    username: currentUser.username,
                    email: currentUser.email,
                    role: currentUser.role,
                    shop: Shop(
                      id: currentUser.shop?.id ?? 1,
                      name: nameCtl.text.trim(),
                      address: addrCtl.text.trim(),
                      phone: phoneCtl.text.trim(),
                      category: catCtl.text.trim(),
                    ),
                  );
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- WORKER PROFILE ---
  Widget _buildWorkerProfile() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.badge, size: 32)),
                const SizedBox(height: 12),
                Text(currentUser.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(currentUser.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Assigned Store'),
                  subtitle: Text(currentUser.shop?.name ?? 'ShopGenie Store'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Account Role'),
                  subtitle: Text(currentUser.role),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
