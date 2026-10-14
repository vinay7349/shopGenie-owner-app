import 'package:flutter/material.dart';
import 'models/product.dart';
import 'models/scan_result.dart';

class UiPreviewScreen extends StatelessWidget {
  const UiPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleProduct = Product(
      id: 1,
      name: 'Aashirvaad Shudh Chakki Atta 5kg',
      category: 'Flour & Atta',
      sellingType: 'UNIT',
      price: 250.0,
      costPrice: 210.0,
      stockQuantity: 15.0,
      isLoose: false,
    );

    final sampleLooseProduct = Product(
      id: 3,
      name: 'Premium Sugar (Loose)',
      category: 'Groceries',
      sellingType: 'KG',
      price: 44.0,
      costPrice: 38.0,
      stockQuantity: 65.0,
      isLoose: true,
    );

    final pages = [
      ('Store Dashboard', '/dashboard', Icons.dashboard_outlined, null),
      ('Products / Catalog', '/products', Icons.inventory_2_outlined, null),
      ('Product Details', '/product_detail', Icons.info_outline, sampleProduct),
      ('Add New Product', '/add_product', Icons.add_box_outlined, null),
      ('Edit Product', '/edit_product', Icons.edit_outlined, sampleProduct),
      ('Stock & Inventory', '/inventory', Icons.warehouse_outlined, null),
      ('AI Camera Scanner', '/scan', Icons.camera_alt_outlined, null),
      ('AI Scan Results Match', '/scan_results', Icons.check_circle_outline, ScanResult(status: 'match', product: sampleProduct, similarity: 0.94)),
      ('Manual Plain-Bag Selection', '/manual_selection', Icons.touch_app_outlined, null),
      ('Smart Scale Weight Entry', '/weight_entry', Icons.scale_outlined, sampleLooseProduct),
      ('Active POS Billing', '/billing', Icons.point_of_sale_outlined, null),
      ('Tax Invoice Receipt', '/invoices', Icons.receipt_long_outlined, null),
      ('Store Profile & Hardware', '/profile', Icons.account_circle_outlined, null),
      ('Merchant Login', '/login', Icons.login_outlined, null),
      ('Register New Store', '/register', Icons.person_add_outlined, null),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShopGenie • All Screen Options Hub'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final page = pages[index];

          return Card(
            elevation: 1,
            shape: RoundedCornerShape(12),
            child: ListTile(
              leading: Icon(page.$3, color: const Color(0xFF006C4C)),
              title: Text(
                page.$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF006C4C)),
              onTap: () {
                if (page.$4 != null) {
                  Navigator.pushNamed(context, page.$2, arguments: page.$4);
                } else {
                  Navigator.pushNamed(context, page.$2);
                }
              },
            ),
          );
        },
      ),
    );
  }
}