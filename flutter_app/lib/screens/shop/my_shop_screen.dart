import 'package:flutter/material.dart';
import '../../models.dart';
import '../../api_service.dart';
import '../../theme/app_theme.dart';
import '../../../widgets.dart';
import 'settings_screen.dart';

class MyShopScreen extends StatelessWidget {
  final ApiService apiService;
  final User user;

  const MyShopScreen({
    super.key,
    required this.apiService,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return _MyShopView(apiService: apiService, user: user);
  }
}

class _MyShopView extends StatefulWidget {
  final ApiService apiService;
  final User user;

  const _MyShopView({required this.apiService, required this.user});

  @override
  State<_MyShopView> createState() => _MyShopViewState();
}

class _MyShopViewState extends State<_MyShopView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late User _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _user = widget.user;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshShop() async {
    setState(() => _isLoading = true);
    try {
      final shop = await widget.apiService.getMyShop();
      if (mounted) {
        setState(() {
          _user = User(
            id: _user.id,
            username: _user.username,
            email: _user.email,
            role: _user.role,
            shop: shop,
          );
        });
      }
    } catch (_) {
      // Ignore error, keep existing data
    } finally {
      if (mounted) setState(() => _isLoading = false);
}
  }

  @override
  Widget build(BuildContext context) {
    final s = _user.shop!;

    return Scaffold(
      appBar: SGAppBar(
        title: 'My Shop',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshShop,
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Settings'),
            ],
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(s),
                SettingsScreen(
                  apiService: widget.apiService,
                  user: _user,
                  onUserUpdated: (updatedUser) => setState(() => _user = updatedUser),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Shop s) {
    return RefreshIndicator(
      onRefresh: _refreshShop,
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SGCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(s.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Chip(
                      label: Text(s.verificationStatus),
                      backgroundColor: AppTheme.paleMint,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s.category,
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (s.description.isNotEmpty) ...[
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(s.description),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                            s.address.isEmpty ? 'Address not set' : s.address)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(s.phone.isEmpty ? '+91 Not Set' : s.phone),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(s.businessHours.isEmpty ? 'Hours not set' : s.businessHours),
                  ],
                ),
                const SizedBox(height: 16),
                SGButton(
                  label: 'Edit Shop Details',
                  icon: Icons.edit_outlined,
                  isOutlined: true,
                  onPressed: _showEditShopDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditShopDialog() {
    final s = _user.shop!;
    final nameCtl = TextEditingController(text: s.name);
    final addrCtl = TextEditingController(text: s.address);
    final phoneCtl = TextEditingController(text: s.phone);
    final catCtl = TextEditingController(text: s.category);
    final hoursCtl = TextEditingController(text: s.businessHours);
    final descCtl = TextEditingController(text: s.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Shop Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SGTextField(controller: nameCtl, label: 'Shop Name*'),
            const SizedBox(height: 12),
            SGTextField(controller: catCtl, label: 'Category'),
            const SizedBox(height: 12),
            SGTextField(controller: descCtl, label: 'Description', maxLines: 3),
            const SizedBox(height: 12),
            SGTextField(controller: addrCtl, label: 'Address'),
            const SizedBox(height: 12),
            SGTextField(controller: phoneCtl, label: 'Phone'),
            const SizedBox(height: 12),
            SGTextField(controller: hoursCtl, label: 'Business Hours'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final updated = await widget.apiService.updateMyShop({
                  'name': nameCtl.text.trim(),
                  'address': addrCtl.text.trim(),
                  'phone': phoneCtl.text.trim(),
                  'category': catCtl.text.trim(),
                  'business_hours': hoursCtl.text.trim(),
                  'description': descCtl.text.trim(),
                });
                if (mounted) {
                  setState(() {
                    _user = User(
                      id: _user.id,
                      username: _user.username,
                      email: _user.email,
                      role: _user.role,
                      shop: updated,
                    );
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}