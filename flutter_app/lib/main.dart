import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

void main() {
  runApp(const ShopGenieApp());
}

class ShopGenieApp extends StatelessWidget {
  const ShopGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopGenie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ApiService _api = ApiService();

  // Mock authenticated state with role toggle for previewing both interfaces
  User currentUser = User(
    id: 1,
    username: 'store_owner',
    email: 'owner@shopgenie.local',
    role: 'SHOP_OWNER',
    shop: Shop(
      name: 'Balaji Kirana & General Store',
      address: 'Shop #4, Market Road, Sector 12',
      category: 'Grocery & Supermarket',
      phone: '+91 98765 43210',
      workerCount: 3,
    ),
  );

  final List<Product> _cart = [];

  void _toggleRole() {
    setState(() {
      if (currentUser.isOwner) {
        currentUser = User(
          id: 2,
          username: 'worker_raj',
          email: 'raj@shopgenie.local',
          role: 'SHOP_WORKER',
          shop: currentUser.shop,
          canConfirmBills: true,
          canViewInvoices: true,
        );
      } else {
        currentUser = User(
          id: 1,
          username: 'store_owner',
          email: 'owner@shopgenie.local',
          role: 'SHOP_OWNER',
          shop: currentUser.shop,
        );
      }
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> ownerPages = [
      _buildOwnerDashboard(),
      _buildBillingPOS(),
      _buildInventoryCatalog(),
      _buildManageWorkers(),
      _buildMyShopScreen(),
    ];

    final List<Widget> workerPages = [
      _buildWorkerDashboard(),
      _buildBillingPOS(),
      _buildWorkerCatalog(),
      _buildWorkerProfile(),
    ];

    final pages = currentUser.isOwner ? ownerPages : workerPages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(currentUser.shop?.name ?? 'ShopGenie'),
          ],
        ),
        actions: [
          Chip(
            label: Text(
              currentUser.role,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            backgroundColor: currentUser.isOwner
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
          ),
          IconButton(
            tooltip: 'Switch Owner/Worker view',
            icon: const Icon(Icons.swap_horiz),
            onPressed: _toggleRole,
          ),
        ],
      ),
      body: pages[_currentIndex < pages.length ? _currentIndex : 0],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex < pages.length ? _currentIndex : 0,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: currentUser.isOwner
            ? const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Billing'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
                NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'Workers'),
                NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'My Shop'),
              ]
            : const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Billing'),
                NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Catalog'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
      ),
    );
  }

  // --- SHOP OWNER DASHBOARD ---
  Widget _buildOwnerDashboard() {
    return ListView(
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
                const Text('Today\'s Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricCol('Gross Sales', '₹18,420', Icons.currency_rupee),
                    _metricCol('Net Profit', '₹3,680', Icons.trending_up, color: Colors.green),
                    _metricCol('Bills', '46', Icons.receipt_long),
                  ],
                ),
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
              child: _quickActionCard('Manage Workers', Icons.people_outline, () => setState(() => _currentIndex = 3)),
            ),
          ],
        ),
      ],
    );
  }

  // --- WORKER DASHBOARD ---
  Widget _buildWorkerDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Colors.blue.withOpacity(0.1),
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
                        Text('Logged in as ${currentUser.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Assigned to: ${currentUser.shop?.name}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Worker Permissions:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('• POS Billing & Camera Capture: ENABLED'),
                const Text('• Product Catalog & Stock Search: ENABLED'),
                Text('• Invoice History Access: ${currentUser.canViewInvoices ? "ENABLED" : "RESTRICTED"}'),
                const Text('• Profit Reports & Cost Prices: HIDDEN (Enforced)'),
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
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- SHARED POS BILLING SCREEN ---
  Widget _buildBillingPOS() {
    final sampleProducts = [
      Product(id: 1, name: 'Toor Dal Premium', sellingPrice: 140.0, currentStock: 45.0, unit: 'kg', isLooseItem: true),
      Product(id: 2, name: 'Basmati Rice 1kg', sellingPrice: 95.0, currentStock: 30.0, unit: 'pc'),
      Product(id: 3, name: 'Tata Salt 1kg', sellingPrice: 28.0, currentStock: 60.0, unit: 'pc'),
      Product(id: 4, name: 'Mustard Oil 1L', sellingPrice: 165.0, currentStock: 25.0, unit: 'pc'),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Scan Barcode or Search Item...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visual Recognition / ESP32-CAM stream initialized')),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sampleProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final p = sampleProducts[idx];
              return ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('₹${p.sellingPrice} / ${p.unit} • Stock: ${p.currentStock}'),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added ${p.name} to bill')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cart Items: 2', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Total: ₹235.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Bill (Atomic)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice created & stock deducted atomically!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- INVENTORY CATALOG (OWNER: shows cost/profit, WORKER: hides) ---
  Widget _buildInventoryCatalog() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Shop Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _productItemCard('Toor Dal Premium', 'Grocery', 140.0, 115.0, 45.0, 'kg', isOwner: currentUser.isOwner),
        _productItemCard('Basmati Rice 1kg', 'Grains', 95.0, 78.0, 30.0, 'pc', isOwner: currentUser.isOwner),
        _productItemCard('Tata Salt 1kg', 'Packaged', 28.0, 22.0, 60.0, 'pc', isOwner: currentUser.isOwner),
      ],
    );
  }

  Widget _buildWorkerCatalog() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Search Products & Availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _productItemCard('Toor Dal Premium', 'Grocery', 140.0, null, 45.0, 'kg', isOwner: false),
        _productItemCard('Basmati Rice 1kg', 'Grains', 95.0, null, 30.0, 'pc', isOwner: false),
        _productItemCard('Tata Salt 1kg', 'Packaged', 28.0, null, 60.0, 'pc', isOwner: false),
      ],
    );
  }

  Widget _productItemCard(String name, String cat, double sell, double? cost, double stock, String unit, {required bool isOwner}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Category: $cat • In Stock: $stock $unit'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹$sell', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (isOwner && cost != null)
              Text('Cost: ₹$cost (Profit: ₹${(sell - cost).toStringAsFixed(1)})', style: const TextStyle(fontSize: 11, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  // --- MANAGE WORKERS (OWNER ONLY) ---
  Widget _buildManageWorkers() {
    final workers = [
      Worker(id: 1, username: 'worker_raj', email: 'raj@shopgenie.local', firstName: 'Raj', lastName: 'Kumar', isWorkerActive: true),
      Worker(id: 2, username: 'worker_amit', email: 'amit@shopgenie.local', firstName: 'Amit', lastName: 'Sharma', isWorkerActive: true),
      Worker(id: 3, username: 'worker_priya', email: 'priya@shopgenie.local', firstName: 'Priya', lastName: 'Patel', isWorkerActive: false),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assigned Shop Workers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            FilledButton.icon(
              onPressed: () => _showAddWorkerDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Worker'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...workers.map((w) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: w.isWorkerActive ? Colors.green.shade100 : Colors.grey.shade200,
              child: Icon(Icons.badge, color: w.isWorkerActive ? Colors.green : Colors.grey),
            ),
            title: Text(w.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${w.email}\nStatus: ${w.isWorkerActive ? "Active" : "Deactivated"}'),
            trailing: Switch(
              value: w.isWorkerActive,
              onChanged: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated ${w.displayName} active status to $val')),
                );
              },
            ),
          ),
        )),
      ],
    );
  }

  void _showAddWorkerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Worker'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Username')),
            TextField(decoration: InputDecoration(labelText: 'Email')),
            TextField(decoration: InputDecoration(labelText: 'Temporary Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Worker invited and assigned to your shop!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // --- MY SHOP SCREEN (SINGLE-SHOP ENFORCED) ---
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
                    Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Chip(
                      label: Text(s.verificationStatus),
                      backgroundColor: Colors.green.withOpacity(0.15),
                      labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Category: ${s.category}', style: const TextStyle(color: Colors.grey)),
                Text('Address: ${s.address}', style: const TextStyle(color: Colors.grey)),
                Text('Phone: ${s.phone}', style: const TextStyle(color: Colors.grey)),
                Text('Hours: ${s.businessHours}', style: const TextStyle(color: Colors.grey)),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.people, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('${s.workerCount} Active Assigned Workers', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Shop Details'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.qr_code),
          title: const Text('Shop QR & Customer Storefront'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Single-Shop Policy Active'),
          subtitle: const Text('Ordinary shop owners manage exactly 1 store'),
          trailing: const Icon(Icons.verified, color: Colors.green),
        ),
      ],
    );
  }

  // --- WORKER PROFILE ---
  Widget _buildWorkerProfile() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(currentUser.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(currentUser.email),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.store),
          title: const Text('Assigned Shop'),
          subtitle: Text(currentUser.shop?.name ?? 'None'),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Role & Permissions'),
          subtitle: const Text('Shop Worker • POS Checkout & Inventory Lookup'),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully')),
            );
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Logout', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _metricCol(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.black87),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
          border: BorderBorder.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF10B981)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
