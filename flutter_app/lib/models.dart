double _parseNum(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

double? _parseNullableNum(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is String) return int.tryParse(val) ?? 0;
  if (val is num) return val.toInt();
  return 0;
}

/// Shop model aligned with ShopOwnerSerializer and ShopPublicSerializer.
class Shop {
  final int id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String phone;
  final String businessHours;
  final String status;
  final double rating;

  Shop({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.address = '',
    this.phone = '',
    this.businessHours = '',
    this.status = 'DRAFT',
    this.rating = 0.0,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      businessHours: json['business_hours']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      rating: _parseNum(json['rating']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'address': address,
    'phone': phone,
    'business_hours': businessHours,
    'status': status,
    'rating': rating,
  };

  /// Convenience getters for UI
  String get verificationStatus => status;
  bool get isActive => status == 'PUBLISHED';
  String? get ownerUsername => null;
  int get workerCount => 0;
}

/// User model aligned with backend authentication response.
class User {
  final int id;
  final String username;
  final String email;
  final String role; // 'SHOP_OWNER', 'SHOP_WORKER', 'CUSTOMER'
  final Shop? shop;
  final bool isWorkerActive;
  final bool canViewInvoices;
  final bool canConfirmBills;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.shop,
    this.isWorkerActive = true,
    this.canViewInvoices = true,
    this.canConfirmBills = true,
  });

  bool get isOwner => role == 'SHOP_OWNER';
  bool get isWorker => role == 'SHOP_WORKER';
  bool get isCustomer => role == 'CUSTOMER';

  factory User.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    final shopJson = json['shop'] as Map<String, dynamic>? ?? json['owned_shop'] as Map<String, dynamic>?;
    return User(
      id: _parseInt(userJson['id']),
      username: userJson['username']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      role: userJson['role']?.toString() ?? 'CUSTOMER',
      shop: shopJson != null ? Shop.fromJson(shopJson) : null,
      isWorkerActive: json['is_worker_active'] as bool? ?? true,
      canViewInvoices: json['can_view_invoices'] as bool? ?? true,
      canConfirmBills: json['can_confirm_bills'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'role': role,
    'shop': shop?.toJson(),
    'is_worker_active': isWorkerActive,
    'can_view_invoices': canViewInvoices,
    'can_confirm_bills': canConfirmBills,
  };
}

/// Worker model aligned with WorkerSerializer.
class Worker {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final bool isWorkerActive;
  final bool canViewInvoices;
  final bool canConfirmBills;
  final String? dateJoined;

  Worker({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.isWorkerActive = true,
    this.canViewInvoices = true,
    this.canConfirmBills = true,
    this.dateJoined,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: _parseInt(json['id']),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      isWorkerActive: json['is_worker_active'] as bool? ?? true,
      canViewInvoices: json['can_view_invoices'] as bool? ?? true,
      canConfirmBills: json['can_confirm_bills'] as bool? ?? true,
      dateJoined: json['date_joined']?.toString(),
    );
  }
}

/// Product model aligned with ProductOwnerSerializer and ProductPublicSerializer.
class Product {
  final int id;
  final String name;
  final String category;
  final String description;
  final double mrp;
  final double sellingPrice;
  final double? costPrice;
  final double stockQuantity;
  final String unit;
  final String imageUrl;
  final String status;
  final String brand;
  final String size;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.mrp,
    required this.sellingPrice,
    this.costPrice,
    required this.stockQuantity,
    required this.unit,
    required this.imageUrl,
    required this.status,
    this.brand = '',
    this.size = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      mrp: _parseNum(json['mrp']),
      sellingPrice: _parseNum(json['selling_price']),
      costPrice: _parseNullableNum(json['cost_price']),
      stockQuantity: _parseNum(json['stock_quantity']),
      unit: json['unit']?.toString() ?? 'PIECE',
      imageUrl: json['image_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      brand: json['brand']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'mrp': mrp,
    'selling_price': sellingPrice,
    'cost_price': costPrice,
    'stock_quantity': stockQuantity,
    'unit': unit,
    'image_url': imageUrl,
    'status': status,
    'brand': brand,
    'size': size,
  };
}

class InvoiceItem {
  final Product product;
  double quantity;
  double price;

  InvoiceItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
    'product': product.id,
    'quantity': quantity,
    'unit_price': price,
  };
}

/// Invoice item from backend response
class InvoiceItemDetail {
  final int id;
  final int? product;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  InvoiceItemDetail({
    required this.id,
    this.product,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory InvoiceItemDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceItemDetail(
      id: _parseInt(json['id']),
      product: json['product'] != null ? _parseInt(json['product']) : null,
      productName: json['product_name']?.toString() ?? '',
      quantity: _parseNum(json['quantity']),
      unitPrice: _parseNum(json['unit_price']),
      lineTotal: _parseNum(json['line_total']),
    );
  }
}

/// Invoice model from backend response
class Invoice {
  final int id;
  final int shop;
  final String idempotencyKey;
  final double totalAmount;
  final String status;
  final String createdAt;
  final List<InvoiceItemDetail> items;

  Invoice({
    required this.id,
    required this.shop,
    required this.idempotencyKey,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List? ?? [];
    return Invoice(
      id: _parseInt(json['id']),
      shop: _parseInt(json['shop']),
      idempotencyKey: json['idempotency_key']?.toString() ?? '',
      totalAmount: _parseNum(json['total_amount']),
      status: json['status']?.toString() ?? 'COMPLETED',
      createdAt: json['created_at']?.toString() ?? '',
      items: itemsJson.map((e) => InvoiceItemDetail.fromJson(e)).toList(),
    );
  }
}

class DashboardData {
  final int shopId;
  final String shopName;
  final String shopStatus;
  final int totalProducts;
  final int availableProducts;
  final int lowStockProducts;
  final int activeOffers;
  final int totalInvoices;
  final double totalSales;
  final int todayInvoices;
  final double todaySales;
  final int activeWorkers;
  final List<dynamic> recentInvoices;

  DashboardData({
    required this.shopId,
    required this.shopName,
    required this.shopStatus,
    required this.totalProducts,
    required this.availableProducts,
    required this.lowStockProducts,
    required this.activeOffers,
    required this.totalInvoices,
    required this.totalSales,
    required this.todayInvoices,
    required this.todaySales,
    required this.activeWorkers,
    required this.recentInvoices,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      shopId: _parseInt(json['shop_id']),
      shopName: json['shop_name']?.toString() ?? 'My Shop',
      shopStatus: json['shop_status']?.toString() ?? 'DRAFT',
      totalProducts: _parseInt(json['total_products']),
      availableProducts: _parseInt(json['available_products']),
      lowStockProducts: _parseInt(json['low_stock_products']),
      activeOffers: _parseInt(json['active_offers']),
      totalInvoices: _parseInt(json['total_invoices']),
      totalSales: _parseNum(json['total_sales']),
      todayInvoices: _parseInt(json['today_invoices']),
      todaySales: _parseNum(json['today_sales']),
      activeWorkers: _parseInt(json['active_workers']),
      recentInvoices: json['recent_invoices'] as List? ?? [],
    );
  }
}

class Offer {
  final int id;
  final int shop;
  final String shopName;
  final String title;
  final String description;
  final String discountType;
  final double discountValue;
  final String scope;
  final int? applicableProduct;
  final String? productName;
  final String startDate;
  final String endDate;
  final bool isActive;
  final bool isValid;
  final String createdAt;
  final String updatedAt;

  Offer({
    required this.id,
    required this.shop,
    required this.shopName,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.scope,
    this.applicableProduct,
    this.productName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isValid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: _parseInt(json['id']),
      shop: _parseInt(json['shop']),
      shopName: json['shop_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'PERCENTAGE',
      discountValue: _parseNum(json['discount_value']),
      scope: json['scope']?.toString() ?? 'STORE_WIDE',
      applicableProduct: json['applicable_product'] != null ? _parseInt(json['applicable_product']) : null,
      productName: json['product_name']?.toString(),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isValid: json['is_valid'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class Announcement {
  final int id;
  final int shop;
  final String shopName;
  final String title;
  final String content;
  final String status;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  Announcement({
    required this.id,
    required this.shop,
    required this.shopName,
    required this.title,
    required this.content,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: _parseInt(json['id']),
      shop: _parseInt(json['shop']),
      shopName: json['shop_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

/// StockAdjustment model aligned with backend StockAdjustmentSerializer.
class StockAdjustment {
  final int id;
  final int product;
  final double delta;
  final String reason;
  final String note;
  final String createdAt;

  StockAdjustment({
    required this.id,
    required this.product,
    required this.delta,
    required this.reason,
    required this.note,
    required this.createdAt,
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: _parseInt(json['id']),
      product: _parseInt(json['product']),
      delta: _parseNum(json['delta']),
      reason: json['reason']?.toString() ?? 'OTHER',
      note: json['note']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product,
    'delta': delta,
    'reason': reason,
    'note': note,
  };
}