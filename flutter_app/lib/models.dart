class Shop {
  final int id;
  final String name;
  final String? address;
  final String category;
  final String? phone;
  final String businessHours;
  final String? description;
  final String verificationStatus;
  final bool isActive;
  final double rating;
  final String? ownerUsername;
  final int workerCount;

  Shop({
    this.id = 1,
    required this.name,
    this.address,
    this.category = 'Grocery & Supermarket',
    this.phone,
    this.businessHours = '08:00 AM - 10:00 PM (Daily)',
    this.description,
    this.verificationStatus = 'VERIFIED',
    this.isActive = true,
    this.rating = 4.8,
    this.ownerUsername,
    this.workerCount = 0,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? 1,
      name: json['name'] ?? '',
      address: json['address'],
      category: json['category'] ?? 'Grocery & Supermarket',
      phone: json['phone'],
      businessHours: json['business_hours'] ?? '08:00 AM - 10:00 PM (Daily)',
      description: json['description'],
      verificationStatus: json['verification_status'] ?? 'VERIFIED',
      isActive: json['is_active'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      ownerUsername: json['owner_username'],
      workerCount: json['worker_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'category': category,
    'phone': phone,
    'business_hours': businessHours,
    'description': description,
    'verification_status': verificationStatus,
    'is_active': isActive,
    'rating': rating,
  };
}

class User {
  final int id;
  final String username;
  final String email;
  final String? shopName;
  final String? phoneNumber;
  final String role; // 'SHOP_OWNER' or 'SHOP_WORKER'
  final Shop? shop;
  final bool isWorkerActive;
  final bool canViewInvoices;
  final bool canConfirmBills;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.shopName,
    this.phoneNumber,
    this.role = 'SHOP_OWNER',
    this.shop,
    this.isWorkerActive = true,
    this.canViewInvoices = true,
    this.canConfirmBills = true,
  });

  bool get isOwner => role == 'SHOP_OWNER';
  bool get isWorker => role == 'SHOP_WORKER';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      shopName: json['shop_name'],
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'SHOP_OWNER',
      shop: json['shop'] != null ? Shop.fromJson(json['shop']) : null,
      isWorkerActive: json['is_worker_active'] ?? true,
      canViewInvoices: json['can_view_invoices'] ?? true,
      canConfirmBills: json['can_confirm_bills'] ?? true,
    );
  }
}

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
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isWorkerActive: json['is_worker_active'] ?? true,
      canViewInvoices: json['can_view_invoices'] ?? true,
      canConfirmBills: json['can_confirm_bills'] ?? true,
      dateJoined: json['date_joined'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? barcode;
  final String category;
  final double sellingPrice;
  final double? costPrice;
  final double currentStock;
  final String unit; // 'kg', 'g', 'pc', 'l'
  final bool isLooseItem;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.category = 'General',
    required this.sellingPrice,
    this.costPrice,
    required this.currentStock,
    this.unit = 'pc',
    this.isLooseItem = false,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      barcode: json['barcode'],
      category: json['category'] ?? 'General',
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'pc',
      isLooseItem: json['is_loose_item'] ?? false,
      imageUrl: json['image_url'],
    );
  }
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
    'product_id': product.id,
    'quantity': quantity,
    'unit_price': price,
  };
}
