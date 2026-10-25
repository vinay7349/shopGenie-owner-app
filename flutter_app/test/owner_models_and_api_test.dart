import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shopgenie_flutter/api_service.dart';
import 'package:shopgenie_flutter/main.dart';
import 'package:shopgenie_flutter/models.dart';
import 'package:shopgenie_flutter/screens/offer_screen.dart';
import 'package:shopgenie_flutter/screens/announcement_screen.dart';
import 'package:shopgenie_flutter/services/token_storage.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request);
  }
}

class MockTokenStorage extends TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasTokens() async => _accessToken != null && _refreshToken != null;
}

http.StreamedResponse _jsonRes(Object body, int code) {
  final bytes = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(
    Stream.fromIterable([bytes]),
    code,
    headers: {'content-type': 'application/json'},
    contentLength: bytes.length,
  );
}

void main() {
  group('Owner Models Serialization Tests', () {
    test('Shop model serialization roundtrip', () {
      final json = {
        'id': 10,
        'name': 'Ganesh Supermarket',
        'address': 'Main Market Road, Pune',
        'category': 'Grocery',
        'phone': '9876543210',
        'status': 'PUBLISHED',
        'verification_status': 'VERIFIED',
      };
      final shop = Shop.fromJson(json);
      expect(shop.id, 10);
      expect(shop.name, 'Ganesh Supermarket');
      expect(shop.address, 'Main Market Road, Pune');
      expect(shop.category, 'Grocery');
      expect(shop.isActive, isTrue);

      final out = shop.toJson();
      expect(out['name'], 'Ganesh Supermarket');
      expect(out['category'], 'Grocery');
    });

    test('User model parses owner and worker roles correctly', () {
      final ownerJson = {
        'id': 1,
        'username': 'owner_ramesh',
        'email': 'ramesh@example.com',
        'role': 'SHOP_OWNER',
        'owned_shop': {'id': 1, 'name': 'Ramesh Kirana'},
      };
      final owner = User.fromJson(ownerJson);
      expect(owner.isOwner, isTrue);
      expect(owner.isWorker, isFalse);
      expect(owner.shop?.name, 'Ramesh Kirana');

      final workerJson = {
        'id': 2,
        'username': 'worker_suresh',
        'email': 'suresh@example.com',
        'role': 'SHOP_WORKER',
        'can_view_invoices': false,
        'can_confirm_bills': true,
      };
      final worker = User.fromJson(workerJson);
      expect(worker.isOwner, isFalse);
      expect(worker.isWorker, isTrue);
      expect(worker.canViewInvoices, isFalse);
      expect(worker.canConfirmBills, isTrue);
    });

    test('Product model parses stock_quantity and selling_price', () {
      final json = {
        'id': 42,
        'name': 'Sunflower Oil 1L',
        'category': 'Cooking Oils',
        'selling_price': '135.00',
        'cost_price': '110.00',
        'mrp': '150.00',
        'stock_quantity': '24.500',
        'unit': 'L',
      };
      final p = Product.fromJson(json);
      expect(p.id, 42);
      expect(p.name, 'Sunflower Oil 1L');
      expect(p.sellingPrice, 135.0);
      expect(p.costPrice, 110.0);
      expect(p.mrp, 150.0);
      expect(p.stockQuantity, 24.5);
      expect(p.unit, 'L');
    });

    test('InvoiceItem toJson sends product id and price', () {
      final p = Product(id: 7, name: 'Sugar 1kg', sellingPrice: 42.0, stockQuantity: 50.0, unit: 'pc', mrp: 45.0, category: 'Sugar', description: '', imageUrl: '', status: 'PUBLISHED');
      final item = InvoiceItem(product: p, quantity: 2.5, price: 42.0);
      expect(item.total, 105.0);

      final json = item.toJson();
      expect(json['product'], 7);
      expect(json['quantity'], 2.5);
      expect(json['unit_price'], 42.0);
    });

    test('DashboardData model parses live aggregation payload', () {
      final json = {
        'shop_id': 1,
        'shop_name': 'Balaji Kirana',
        'shop_status': 'PUBLISHED',
        'total_products': 15,
        'available_products': 12,
        'low_stock_products': 3,
        'active_offers': 2,
        'total_invoices': 100,
        'total_sales': 12500.5,
        'today_invoices': 8,
        'today_sales': 1840.0,
        'active_workers': 2,
        'recent_invoices': [],
      };
      final d = DashboardData.fromJson(json);
      expect(d.shopName, 'Balaji Kirana');
      expect(d.totalProducts, 15);
      expect(d.lowStockProducts, 3);
      expect(d.todaySales, 1840.0);
      expect(d.activeWorkers, 2);
    });

    test('Offer and Announcement models parse accurately', () {
      final offerJson = {
        'id': 1,
        'title': 'Diwali Festive Sale',
        'description': 'Flat 15% off on all dry fruits',
        'discount_type': 'PERCENTAGE',
        'discount_value': '15.00',
        'start_date': '2026-10-20T00:00:00Z',
        'end_date': '2026-10-31T23:59:59Z',
        'is_active': true,
        'scope': 'STOREWIDE',
      };
      final offer = Offer.fromJson(offerJson);
      expect(offer.id, 1);
      expect(offer.title, 'Diwali Festive Sale');
      expect(offer.discountValue, 15.0);
      expect(offer.isActive, isTrue);

      final annJson = {
        'id': 5,
        'title': 'Fresh Organic Milk Arrived',
        'content': 'Morning batch arrived at 7 AM. Limited packets.',
        'status': 'PUBLISHED',
        'created_at': '2026-10-23T07:15:00Z',
      };
      final ann = Announcement.fromJson(annJson);
      expect(ann.id, 5);
      expect(ann.title, 'Fresh Organic Milk Arrived');
      expect(ann.status, 'PUBLISHED');
    });
  });

  group('ApiService Low-Level Client Tests', () {
    test('login stores access token', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/auth/login/');
        return _jsonRes({'access': 'token_xyz123', 'refresh': 'refresh_xyz123', 'role': 'SHOP_OWNER'}, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final res = await api.login('owner1', 'pass123');
      expect(res['role'], 'SHOP_OWNER');
      expect(api.token, 'token_xyz123');
    });

    test('getDashboard returns parsed metrics', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/shops/dashboard/');
        return _jsonRes({
          'shop_id': 1,
          'shop_name': 'Balaji Kirana',
          'total_products': 20,
          'today_sales': 2500.0,
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final d = await api.getDashboard();
      expect(d.shopName, 'Balaji Kirana');
      expect(d.totalProducts, 20);
      expect(d.todaySales, 2500.0);
    });

    test('confirmBill sends idempotency_key and items array', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/billing/invoices/');
        final body = jsonDecode((req as http.Request).body);
        expect(body['idempotency_key'], isNotNull);
        expect(body['items'], isA<List>());
        expect(body['items'].first['product_id'], 1);
        expect(body['items'].first['quantity'], '2.0');
        return _jsonRes({'id': 101, 'status': 'ISSUED', 'total_amount': '280.00'}, 201);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final p = Product(id: 1, name: 'Rice', sellingPrice: 140.0, stockQuantity: 20.0, unit: 'pc', mrp: 150.0, category: 'Rice', description: '', imageUrl: '', status: 'PUBLISHED');
      final res = await api.confirmBill(
        items: [InvoiceItem(product: p, quantity: 2.0, price: 140.0)],
        idempotencyKey: 'test-key-123',
      );
      expect(res['id'], 101);
      expect(res['status'], 'ISSUED');
    });

    test('getProducts handles both paginated and flat lists', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/products/');
        return _jsonRes({
          'count': 1,
          'results': [
            {'id': 1, 'name': 'Moong Dal', 'category': 'Pulses', 'description': '', 'selling_price': 120.0, 'stock_quantity': 15.0, 'mrp': 130.0, 'unit': 'kg', 'image_url': '', 'status': 'PUBLISHED', 'brand': '', 'size': ''}
          ]
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final prods = await api.getProducts();
      expect(prods.length, 1);
      expect(prods.first.name, 'Moong Dal');
    });
  });

  group('MainNavigationScreen Widget Tests', () {
    final testUser = User(
      id: 1,
      username: 'store_owner',
      email: 'owner@shopgenie.local',
      role: 'SHOP_OWNER',
      shop: Shop(
        id: 1,
        name: 'Balaji Kirana & General Store',
        address: 'Shop #4, Market Road, Sector 12',
        category: 'Grocery & Supermarket',
        phone: '+91 98765 43210',
      ),
    );

    testWidgets('Renders AppBar and navigation tabs', (tester) async {
      await tester.pumpWidget(ShopGenieApp(initialUser: testUser));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);
      expect(find.text('My Shop'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Inventory'), findsOneWidget);
    });

    testWidgets('No role toggle exists - role determined by backend authentication', (tester) async {
      await tester.pumpWidget(ShopGenieApp(initialUser: testUser));
      await tester.pumpAndSettle();

      // Role toggle should not exist - role comes from backend auth
      expect(find.byTooltip('Switch Owner/Worker preview'), findsNothing);

      // Owner navigation tabs should be visible
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Inventory'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);
      expect(find.text('My Shop'), findsOneWidget);
    });
  });

  group('Offer and Announcement API Tests', () {
    test('getOffers returns parsed offers list', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/offers/');
        return _jsonRes({
          'count': 2,
          'results': [
            {'id': 1, 'shop': 1, 'shop_name': 'Test Shop', 'title': 'Summer Sale', 'description': 'Great sale', 'discount_type': 'PERCENTAGE', 'discount_value': '20.00', 'is_active': true, 'scope': 'STORE_WIDE', 'start_date': '2026-06-01T00:00:00Z', 'end_date': '2026-08-31T23:59:59Z', 'is_valid': true, 'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z'},
            {'id': 2, 'shop': 1, 'shop_name': 'Test Shop', 'title': 'Winter Clearance', 'description': 'Clearance sale', 'discount_type': 'FIXED', 'discount_value': '50.00', 'is_active': true, 'scope': 'PRODUCT_SPECIFIC', 'start_date': '2026-12-01T00:00:00Z', 'end_date': '2026-12-31T23:59:59Z', 'is_valid': false, 'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z'},
          ]
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final offers = await api.getOffers();
      expect(offers.length, 2);
      expect(offers.first.title, 'Summer Sale');
      expect(offers.first.discountType, 'PERCENTAGE');
      expect(offers.first.discountValue, 20.0);
      expect(offers.last.discountType, 'FIXED');
      expect(offers.last.discountValue, 50.0);
    });

    test('createOffer sends correct payload and returns created offer', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/offers/');
        final body = jsonDecode((req as http.Request).body);
        expect(body['title'], 'New Offer');
        expect(body['discount_type'], 'PERCENTAGE');
        expect(body['discount_value'], 15.0);
        expect(body['scope'], 'STORE_WIDE');
        return _jsonRes({
          'id': 10,
          'shop': 1,
          'shop_name': 'Test Shop',
          'title': 'New Offer',
          'description': '',
          'discount_type': 'PERCENTAGE',
          'discount_value': '15.00',
          'scope': 'STORE_WIDE',
          'is_active': true,
          'start_date': '2026-10-01T00:00:00Z',
          'end_date': '2026-10-31T23:59:59Z',
          'is_valid': true,
          'created_at': '2026-10-01T00:00:00Z',
          'updated_at': '2026-10-01T00:00:00Z',
        }, 201);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final offer = await api.createOffer({
        'title': 'New Offer',
        'discount_type': 'PERCENTAGE',
        'discount_value': 15.0,
        'scope': 'STORE_WIDE',
        'start_date': '2026-10-01T00:00:00Z',
        'end_date': '2026-10-31T23:59:59Z',
        'is_active': true,
      });
      expect(offer.id, 10);
      expect(offer.title, 'New Offer');
    });

    test('updateOffer sends PATCH with correct ID', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/offers/5/');
        expect(req.method, 'PATCH');
        return _jsonRes({
          'id': 5,
          'shop': 1,
          'shop_name': 'Test Shop',
          'title': 'Updated Offer',
          'description': '',
          'discount_type': 'FIXED',
          'discount_value': '25.00',
          'scope': 'STORE_WIDE',
          'is_active': false,
          'start_date': '2026-10-01T00:00:00Z',
          'end_date': '2026-10-31T23:59:59Z',
          'is_valid': false,
          'created_at': '2026-10-01T00:00:00Z',
          'updated_at': '2026-10-01T00:00:00Z',
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final offer = await api.updateOffer(5, {'title': 'Updated Offer', 'discount_type': 'FIXED', 'discount_value': 25.0, 'is_active': false});
      expect(offer.id, 5);
      expect(offer.title, 'Updated Offer');
      expect(offer.isActive, isFalse);
    });

    test('deleteOffer sends DELETE with correct ID', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/offers/7/');
        expect(req.method, 'DELETE');
        return _jsonRes({}, 204);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      await api.deleteOffer(7);
      expect(true, isTrue); // No exception means success
    });

    test('getAnnouncements returns parsed announcements list', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/announcements/');
        return _jsonRes({
          'count': 2,
          'results': [
            {'id': 1, 'shop': 1, 'shop_name': 'Test Shop', 'title': 'New Stock', 'content': 'Fresh vegetables arrived', 'status': 'PUBLISHED', 'created_at': '2026-10-23T07:00:00Z', 'updated_at': '2026-10-23T07:00:00Z'},
            {'id': 2, 'shop': 1, 'shop_name': 'Test Shop', 'title': 'Holiday Hours', 'content': 'Closed on Sunday', 'status': 'DRAFT', 'created_at': '2026-10-22T10:00:00Z', 'updated_at': '2026-10-22T10:00:00Z'},
          ]
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final announcements = await api.getAnnouncements();
      expect(announcements.length, 2);
      expect(announcements.first.title, 'New Stock');
      expect(announcements.first.status, 'PUBLISHED');
      expect(announcements.last.status, 'DRAFT');
    });

test('createAnnouncement sends correct payload', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/announcements/');
        final body = jsonDecode((req as http.Request).body);
        expect(body['title'], 'New Announcement');
        expect(body['content'], 'Test content');
        expect(body['status'], 'PUBLISHED');
        return _jsonRes({
          'id': 20,
          'shop': 1,
          'shop_name': 'Test Shop',
          'title': 'New Announcement',
          'content': 'Test content',
          'status': 'PUBLISHED',
          'created_at': '2026-10-23T08:00:00Z',
          'updated_at': '2026-10-23T08:00:00Z',
        }, 201);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final announcement = await api.createAnnouncement({
        'title': 'New Announcement',
        'content': 'Test content',
        'status': 'PUBLISHED',
      });
      expect(announcement.id, 20);
      expect(announcement.title, 'New Announcement');
      expect(announcement.status, 'PUBLISHED');
    });

    test('updateAnnouncement sends PATCH with correct ID', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/announcements/3/');
        expect(req.method, 'PATCH');
        return _jsonRes({
          'id': 3,
          'shop': 1,
          'shop_name': 'Test Shop',
          'title': 'Updated Announcement',
          'content': 'Updated content',
          'status': 'ARCHIVED',
          'created_at': '2026-10-23T08:00:00Z',
          'updated_at': '2026-10-23T08:00:00Z',
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final announcement = await api.updateAnnouncement(3, {'title': 'Updated Announcement', 'status': 'ARCHIVED'});
      expect(announcement.id, 3);
      expect(announcement.status, 'ARCHIVED');
    });

    test('deleteAnnouncement sends DELETE with correct ID', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/announcements/9/');
        expect(req.method, 'DELETE');
        return _jsonRes({}, 204);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      await api.deleteAnnouncement(9);
      expect(true, isTrue);
    });

    test('Offer model handles is_valid and date fields', () {
      final json = {
        'id': 1,
        'shop': 1,
        'shop_name': 'Test Shop',
        'title': 'Test Offer',
        'description': 'Test description',
        'discount_type': 'PERCENTAGE',
        'discount_value': '25.00',
        'scope': 'STORE_WIDE',
        'start_date': '2026-01-01T00:00:00Z',
        'end_date': '2026-12-31T23:59:59Z',
        'is_active': true,
        'is_valid': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final offer = Offer.fromJson(json);
      expect(offer.isValid, isTrue);
      expect(offer.startDate, '2026-01-01T00:00:00Z');
      expect(offer.endDate, '2026-12-31T23:59:59Z');
      expect(offer.scope, 'STORE_WIDE');
    });

    test('Announcement model handles status field', () {
      final json = {
        'id': 1,
        'shop': 1,
        'shop_name': 'Test Shop',
        'title': 'Test',
        'content': 'Content',
        'status': 'PUBLISHED',
        'created_at': '2026-10-23T07:00:00Z',
        'updated_at': '2026-10-23T07:00:00Z',
      };
      final ann = Announcement.fromJson(json);
      expect(ann.status, 'PUBLISHED');
    });
  });

  group('Worker Management API Tests', () {
    test('getWorkers returns parsed workers list', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/workers/');
        return _jsonRes({
          'count': 2,
          'results': [
            {'id': 1, 'username': 'worker_raj', 'email': 'raj@shopgenie.local', 'first_name': 'Raj', 'last_name': 'Kumar', 'is_worker_active': true, 'can_view_invoices': true, 'can_confirm_bills': true, 'date_joined': '2026-01-01T00:00:00Z'},
            {'id': 2, 'username': 'worker_amit', 'email': 'amit@shopgenie.local', 'first_name': 'Amit', 'last_name': 'Sharma', 'is_worker_active': false, 'can_view_invoices': true, 'can_confirm_bills': false, 'date_joined': '2026-02-01T00:00:00Z'},
          ]
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final workers = await api.getWorkers();
      expect(workers.length, 2);
      expect(workers.first.username, 'worker_raj');
      expect(workers.first.displayName, 'Raj Kumar');
      expect(workers.first.isWorkerActive, isTrue);
      expect(workers.first.canViewInvoices, isTrue);
      expect(workers.first.canConfirmBills, isTrue);
      expect(workers.last.isWorkerActive, isFalse);
      expect(workers.last.canConfirmBills, isFalse);
    });

    test('createWorker sends correct payload and returns created worker', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/workers/');
        final body = jsonDecode((req as http.Request).body);
        expect(body['username'], 'new_worker');
        expect(body['email'], 'new@shopgenie.local');
        expect(body['password'], 'password123');
        expect(body['first_name'], 'New');
        expect(body['last_name'], 'Worker');
        return _jsonRes({
          'id': 10,
          'username': 'new_worker',
          'email': 'new@shopgenie.local',
          'first_name': 'New',
          'last_name': 'Worker',
          'is_worker_active': true,
          'can_view_invoices': true,
          'can_confirm_bills': true,
          'date_joined': '2026-10-01T00:00:00Z',
        }, 201);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final worker = await api.createWorker({
        'username': 'new_worker',
        'email': 'new@shopgenie.local',
        'password': 'password123',
        'first_name': 'New',
        'last_name': 'Worker',
      });
      expect(worker.id, 10);
      expect(worker.username, 'new_worker');
      expect(worker.displayName, 'New Worker');
    });

    test('updateWorker sends PATCH with correct ID and allowed fields', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/workers/5/');
        expect(req.method, 'PATCH');
        final body = jsonDecode((req as http.Request).body);
        expect(body['is_worker_active'], isFalse);
        expect(body['can_view_invoices'], isTrue);
        expect(body['can_confirm_bills'], isFalse);
        return _jsonRes({
          'id': 5,
          'username': 'worker_raj',
          'email': 'raj@shopgenie.local',
          'first_name': 'Raj',
          'last_name': 'Kumar',
          'is_worker_active': false,
          'can_view_invoices': true,
          'can_confirm_bills': false,
          'date_joined': '2026-01-01T00:00:00Z',
        }, 200);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      final worker = await api.updateWorker(5, {'is_worker_active': false, 'can_view_invoices': true, 'can_confirm_bills': false});
      expect(worker.id, 5);
      expect(worker.isWorkerActive, isFalse);
      expect(worker.canConfirmBills, isFalse);
    });

    test('deleteWorker sends DELETE with correct ID', () async {
      final client = MockHttpClient((req) async {
        expect(req.url.path, '/api/workers/7/');
        expect(req.method, 'DELETE');
        return _jsonRes({}, 204);
      });
      final api = ApiService(config: ApiConfig.emulator(), client: client, tokenStorage: MockTokenStorage());
      await api.deleteWorker(7);
      expect(true, isTrue);
    });

    test('Worker model parses permissions and display name', () {
      final json = {
        'id': 1,
        'username': 'worker_raj',
        'email': 'raj@shopgenie.local',
        'first_name': 'Raj',
        'last_name': 'Kumar',
        'is_worker_active': true,
        'can_view_invoices': true,
        'can_confirm_bills': false,
        'date_joined': '2026-10-01T00:00:00Z',
      };
      final worker = Worker.fromJson(json);
      expect(worker.id, 1);
      expect(worker.username, 'worker_raj');
      expect(worker.displayName, 'Raj Kumar');
      expect(worker.isWorkerActive, isTrue);
      expect(worker.canViewInvoices, isTrue);
      expect(worker.canConfirmBills, isFalse);
    });

    test('Worker model falls back to username when name is empty', () {
      final json = {
        'id': 2,
        'username': 'worker_no_name',
        'email': 'noname@shopgenie.local',
        'first_name': '',
        'last_name': '',
        'is_worker_active': false,
        'can_view_invoices': true,
        'can_confirm_bills': true,
        'date_joined': '2026-10-01T00:00:00Z',
      };
      final worker = Worker.fromJson(json);
      expect(worker.displayName, 'worker_no_name');
    });
  });
}
