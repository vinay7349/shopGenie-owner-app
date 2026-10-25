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
import 'screens/dashboard/owner_dashboard_screen.dart';
import 'screens/dashboard/worker_dashboard_screen.dart';
import 'screens/shop/my_shop_screen.dart';
import 'widgets.dart';

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
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService(config: ApiConfig.emulator());
    _currentUser = widget.initialUser;
  }

  void _handleLoginSuccess(User user) {
    setState(() {
      _currentUser = user;
      _currentTab = 0;
    });
  }

  void _handleLogout() {
    _api.clearTokens();
    setState(() {
      _currentUser = null;
      _currentTab = 0;
    });
  }

  void _onNavigate(int index) {
    if (mounted) {
      setState(() => _currentTab = index);
    }
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
              initialTab: _currentTab,
              onNavigate: _onNavigate,
            ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final ApiService apiService;
  final User initialUser;
  final VoidCallback onLogout;
  final int initialTab;
  final ValueChanged<int> onNavigate;

  const MainNavigationScreen({
    super.key,
    required this.apiService,
    required this.initialUser,
    required this.onLogout,
    this.initialTab = 0,
    required this.onNavigate,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _currentUser = widget.initialUser;
  }

  @override
  Widget build(BuildContext context) {
    final List<SGBottomNavItem> ownerItems = const [
      SGBottomNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
      SGBottomNavItem(label: 'Billing', icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale),
      SGBottomNavItem(label: 'Inventory', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2),
      SGBottomNavItem(label: 'Offers', icon: Icons.local_offer_outlined, selectedIcon: Icons.local_offer),
      SGBottomNavItem(label: 'Announcements', icon: Icons.campaign_outlined, selectedIcon: Icons.campaign),
      SGBottomNavItem(label: 'Workers', icon: Icons.badge_outlined, selectedIcon: Icons.badge),
      SGBottomNavItem(label: 'My Shop', icon: Icons.store_outlined, selectedIcon: Icons.store),
    ];

    final List<SGBottomNavItem> workerItems = const [
      SGBottomNavItem(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
      SGBottomNavItem(label: 'Billing', icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale),
      SGBottomNavItem(label: 'Catalog', icon: Icons.search, selectedIcon: Icons.search),
      SGBottomNavItem(label: 'Profile', icon: Icons.person_outline, selectedIcon: Icons.person),
    ];

    final items = _currentUser.isOwner ? ownerItems : workerItems;

    return Scaffold(
      appBar: SGAppBar(
        title: _currentUser.shop?.name ?? 'ShopGenie',
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              _currentUser.role,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            backgroundColor: _currentUser.isOwner
                ? AppTheme.paleMint
                : Colors.blue.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildPages(),
      ),
      bottomNavigationBar: SGBottomNavigationBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          widget.onNavigate(idx);
        },
        items: items,
      ),
    );
  }

  List<Widget> _buildPages() {
    if (_currentUser.isOwner) {
      return [
        OwnerDashboardScreen(
          apiService: widget.apiService,
          user: _currentUser,
          onNavigate: widget.onNavigate,
        ),
        BillingScreen(
          apiService: widget.apiService,
          isOwner: true,
        ),
        InventoryScreen(
          apiService: widget.apiService,
          isOwner: true,
          currentUser: _currentUser,
        ),
        OfferScreen(apiService: widget.apiService),
        AnnouncementScreen(apiService: widget.apiService),
        WorkerManagementScreen(apiService: widget.apiService),
        MyShopScreen(
          apiService: widget.apiService,
          user: _currentUser,
        ),
      ];
    } else {
      return [
        WorkerDashboardScreen(
          apiService: widget.apiService,
          user: _currentUser,
          onNavigate: widget.onNavigate,
        ),
        BillingScreen(
          apiService: widget.apiService,
          isOwner: false,
        ),
        InventoryScreen(
          apiService: widget.apiService,
          isOwner: false,
          currentUser: _currentUser,
        ),
        _buildWorkerProfile(),
      ];
    }
  }

  Widget _buildWorkerProfile() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SGCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.badge, size: 32)),
              const SizedBox(height: 12),
              Text(_currentUser.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_currentUser.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Assigned Store'),
                subtitle: Text(_currentUser.shop?.name ?? 'ShopGenie Store'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Account Role'),
                subtitle: Text(_currentUser.role),
              ),
            ],
          ),
        ),
      ],
    );
  }
}