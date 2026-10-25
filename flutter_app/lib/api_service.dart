import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'services/token_storage.dart';

/// Exception for API errors with status code and body.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  static String baseUrl = 'http://127.0.0.1:8000/api';
  String? _token;
  final TokenStorage _tokenStorage;
  final http.Client _client;

  /// Creates an ApiService with optional base URL, HTTP client, and token storage.
  /// For testing, provide a mock [http.Client] and [TokenStorage].
  ApiService({
    String? initialBaseUrl,
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    if (initialBaseUrl != null) {
      baseUrl = initialBaseUrl;
    }
  }

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers() {
    final map = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  /// Loads tokens from secure storage into memory.
  Future<void> loadStoredTokens() async {
    final access = await _tokenStorage.getAccessToken();
    if (access != null && access.isNotEmpty) {
      _token = access;
    }
  }

  /// Clears tokens from memory and secure storage.
  Future<void> clearTokens() async {
    _token = null;
    await _tokenStorage.clearTokens();
  }

  /// Checks if we have valid tokens stored.
  Future<bool> hasValidTokens() async {
    return _tokenStorage.hasTokens();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (_token != null && refresh != null) {
        await _tokenStorage.saveTokens(accessToken: _token!, refreshToken: refresh);
      }
      return data;
    } else {
      final body = res.body;
      throw ApiException('Login failed', statusCode: res.statusCode, responseBody: body);
    }
  }

  Future<Map<String, dynamic>> registerOwner({
    required String username,
    required String email,
    required String password,
    required String shopName,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/register/owner/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'shop_name': shopName,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (_token != null && refresh != null) {
        await _tokenStorage.saveTokens(accessToken: _token!, refreshToken: refresh);
      }
      return data;
    } else {
      final body = res.body;
      throw ApiException('Registration failed', statusCode: res.statusCode, responseBody: body);
    }
  }

  /// Refreshes the access token using the stored refresh token.
  /// Returns the new access token on success, or null if refresh failed.
  Future<String?> refreshToken() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return null;
    }

    final res = await _client.post(
      Uri.parse('$baseUrl/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final newAccess = data['access'] as String?;
      final newRefresh = data['refresh'] as String?;
      if (newAccess != null) {
        _token = newAccess;
        await _tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh ?? refresh,
        );
        return newAccess;
      }
    }
    return null;
  }

  Future<Shop> getMyShop() async {
    final res = await _client.get(Uri.parse('$baseUrl/shops/my_shop/'), headers: _headers());
    if (res.statusCode == 200) {
      return Shop.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getMyShop());
    }
    throw ApiException('Failed to load shop', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Shop> updateMyShop(Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/shops/my_shop/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Shop.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => updateMyShop(body));
    }
    throw ApiException('Failed to update shop', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<DashboardData> getDashboard() async {
    final res = await _client.get(Uri.parse('$baseUrl/shops/dashboard/'), headers: _headers());
    if (res.statusCode == 200) {
      return DashboardData.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getDashboard());
    }
    throw ApiException('Failed to load dashboard', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<List<Worker>> getWorkers() async {
    final res = await _client.get(Uri.parse('$baseUrl/workers/'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded is Map && decoded['results'] is List
          ? decoded['results']
          : (decoded is List ? decoded : []);
      return list.map((e) => Worker.fromJson(e)).toList();
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getWorkers());
    }
    throw ApiException('Failed to load workers', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Worker> createWorker(Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/workers/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Worker.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => createWorker(body));
    }
    throw ApiException('Failed to create worker', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Worker> updateWorker(int id, Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/workers/$id/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Worker.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => updateWorker(id, body));
    }
    throw ApiException('Failed to update worker', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<void> deleteWorker(int id) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/workers/$id/'),
      headers: _headers(),
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => deleteWorker(id));
    }
    throw ApiException('Failed to delete worker', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<List<Product>> getProducts() async {
    final res = await _client.get(Uri.parse('$baseUrl/products/'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded is Map && decoded['results'] is List
          ? decoded['results']
          : (decoded is List ? decoded : []);
      return list.map((e) => Product.fromJson(e)).toList();
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getProducts());
    }
    throw ApiException('Failed to load products', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/products/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => createProduct(body));
    }
    throw ApiException('Failed to create product', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/products/$id/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => updateProduct(id, body));
    }
    throw ApiException('Failed to update product', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Map<String, dynamic>> confirmBill({
    required List<InvoiceItem> items,
    required String idempotencyKey,
    String paymentMode = '',
    String customerName = '',
    String customerPhone = '',
  }) async {
    final body = {
      'idempotency_key': idempotencyKey,
      'payment_mode': paymentMode,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'items': items.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity.toString(),
      }).toList(),
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/billing/invoices/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => confirmBill(items: items, idempotencyKey: idempotencyKey, paymentMode: paymentMode, customerName: customerName, customerPhone: customerPhone));
    }
    if (res.statusCode == 409) {
      // Idempotency key conflict - different payload
      final data = jsonDecode(res.body);
      throw ApiException(data['detail'] ?? 'Idempotency key reused with different payload', statusCode: 409, responseBody: res.body);
    }
    throw ApiException('Bill confirmation failed', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<List<dynamic>> getInvoices() async {
    final res = await _client.get(Uri.parse('$baseUrl/billing/invoices/'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded is Map && decoded['results'] is List
          ? decoded['results']
          : (decoded is List ? decoded : []);
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getInvoices());
    }
    throw ApiException('Failed to load invoices', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Map<String, dynamic>> getInvoice(int id) async {
    final res = await _client.get(Uri.parse('$baseUrl/billing/invoices/$id/'), headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getInvoice(id));
    }
    throw ApiException('Failed to load invoice', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<List<Offer>> getOffers() async {
    final res = await _client.get(Uri.parse('$baseUrl/offers/'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded is Map && decoded['results'] is List
          ? decoded['results']
          : (decoded is List ? decoded : []);
      return list.map((e) => Offer.fromJson(e)).toList();
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getOffers());
    }
    throw ApiException('Failed to load offers', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Offer> createOffer(Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/offers/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Offer.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => createOffer(body));
    }
    throw ApiException('Failed to create offer', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<List<Announcement>> getAnnouncements() async {
    final res = await _client.get(Uri.parse('$baseUrl/announcements/'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded is Map && decoded['results'] is List
          ? decoded['results']
          : (decoded is List ? decoded : []);
      return list.map((e) => Announcement.fromJson(e)).toList();
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getAnnouncements());
    }
    throw ApiException('Failed to load announcements', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/announcements/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Announcement.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => createAnnouncement(body));
    }
    throw ApiException('Failed to create announcement', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<Offer> updateOffer(int id, Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/offers/$id/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Offer.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => updateOffer(id, body));
    }
    throw ApiException('Failed to update offer', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<void> deleteOffer(int id) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/offers/$id/'),
      headers: _headers(),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      if (res.statusCode == 401) {
        await _tryRefreshAndRetry(() => deleteOffer(id));
      }
      throw ApiException('Failed to delete offer', statusCode: res.statusCode, responseBody: res.body);
    }
  }

  Future<Announcement> updateAnnouncement(int id, Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/announcements/$id/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Announcement.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => updateAnnouncement(id, body));
    }
    throw ApiException('Failed to update announcement', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<void> deleteAnnouncement(int id) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/announcements/$id/'),
      headers: _headers(),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      if (res.statusCode == 401) {
        await _tryRefreshAndRetry(() => deleteAnnouncement(id));
      }
      throw ApiException('Failed to delete announcement', statusCode: res.statusCode, responseBody: res.body);
    }
  }

  // --- Inventory / Stock Adjustments ---

  Future<List<StockAdjustment>> getStockAdjustments() async {
    final res = await _client.get(Uri.parse('$baseUrl/inventory/'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded is Map && decoded['results'] is List
          ? decoded['results']
          : (decoded is List ? decoded : []);
      return list.map((e) => StockAdjustment.fromJson(e)).toList();
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => getStockAdjustments());
    }
    throw ApiException('Failed to load stock adjustments', statusCode: res.statusCode, responseBody: res.body);
  }

  Future<StockAdjustment> createStockAdjustment({
    required int productId,
    required double delta,
    required String reason,
    String note = '',
  }) async {
    final body = {
      'product': productId,
      'delta': delta,
      'reason': reason,
      'note': note,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/inventory/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return StockAdjustment.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 401) {
      await _tryRefreshAndRetry(() => createStockAdjustment(productId: productId, delta: delta, reason: reason, note: note));
    }
    throw ApiException('Failed to create stock adjustment', statusCode: res.statusCode, responseBody: res.body);
  }

  /// Attempts to refresh the token and retry the request once.
  /// If refresh fails, clears tokens and rethrows the original error.
  Future<T> _tryRefreshAndRetry<T>(Future<T> Function() request) async {
    final newToken = await refreshToken();
    if (newToken != null) {
      return request();
    } else {
      await clearTokens();
      throw ApiException('Session expired. Please log in again.', statusCode: 401);
    }
  }

  void close() => _client.close();
}