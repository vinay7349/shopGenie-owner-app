import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'models.dart';
import 'services/token_storage.dart';

/// Exception for API errors with status code and body.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.responseBody, this.errorCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode, code: $errorCode)';
}

/// Configuration for API client
class ApiConfig {
  /// Base URL for API (e.g., 'http://10.0.2.2:8000/api' for emulator, 'http://192.168.1.100:8000/api' for physical device)
  final String baseUrl;

  /// Connection timeout
  final Duration connectTimeout;

  /// Request timeout
  final Duration requestTimeout;

  /// Whether to enable debug logging (sanitized)
  final bool enableLogging;

  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 30),
    this.enableLogging = false,
  });

  /// Factory for emulator (Android emulator uses 10.0.2.2 to reach host machine)
  factory ApiConfig.emulator({int port = 8000}) => ApiConfig(
    baseUrl: 'http://10.0.2.2:$port/api',
    enableLogging: true,
  );

  /// Factory for physical device via LAN IP
  factory ApiConfig.physicalDevice(String lanIp, {int port = 8000}) => ApiConfig(
    baseUrl: 'http://$lanIp:$port/api',
    enableLogging: false,
  );

  /// Factory for production (HTTPS)
  factory ApiConfig.production(String domain, {int port = 443}) => ApiConfig(
    baseUrl: 'https://$domain${port != 443 ? ':$port' : ''}/api',
    enableLogging: false,
  );
}

/// Centralized API client with JWT auth, token refresh, timeouts, and safe retries.
class ApiService {
  final ApiConfig _config;
  final TokenStorage _tokenStorage;
  final http.Client _client;
  String? _token;

  /// Creates an ApiService with the given configuration.
  /// For testing, provide a mock [http.Client] and [TokenStorage].
  ApiService({
    required ApiConfig config,
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : _config = config,
        _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  String? get token => _token;

  String get baseUrl => _config.baseUrl;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers() {
    final map = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  /// Logs a sanitized message (never logs tokens, passwords, or sensitive data)
  void _log(String message) {
    if (_config.enableLogging) {
      debugPrint('[ApiService] $message');
    }
  }

  /// Loads tokens from secure storage into memory.
  Future<void> loadStoredTokens() async {
    final access = await _tokenStorage.getAccessToken();
    if (access != null && access.isNotEmpty) {
      _token = access;
      _log('Loaded stored access token');
    }
  }

  /// Clears tokens from memory and secure storage.
  Future<void> clearTokens() async {
    _token = null;
    await _tokenStorage.clearTokens();
    _log('Cleared tokens');
  }

  /// Checks if we have valid tokens stored.
  Future<bool> hasValidTokens() async {
    return _tokenStorage.hasTokens();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _log('Login attempt for user: $username');
    final res = await _post<Map<String, dynamic>>(
      '/auth/login/',
      {'username': username, 'password': password},
      (json) => json,
    );
    final access = res['access'] as String?;
    final refresh = res['refresh'] as String?;
    if (access != null && refresh != null) {
      _token = access;
      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
    }
    _log('Login successful for user: $username');
    return res;
  }

  Future<Map<String, dynamic>> registerOwner({
    required String username,
    required String email,
    required String password,
    required String shopName,
  }) async {
    _log('Register owner attempt for user: $username, shop: $shopName');
    final res = await _post<Map<String, dynamic>>(
      '/auth/register/owner/',
      {
        'username': username,
        'email': email,
        'password': password,
        'shop_name': shopName,
      },
      (json) => json,
    );
    final access = res['access'] as String?;
    final refresh = res['refresh'] as String?;
    if (access != null && refresh != null) {
      _token = access;
      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
    }
    _log('Register owner successful for user: $username');
    return res;
  }

  /// Refreshes the access token using the stored refresh token.
  /// Returns the new access token on success, or null if refresh failed.
  Future<String?> refreshToken() async {
    _log('Attempting token refresh');
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      _log('No refresh token available');
      return null;
    }

    try {
      final res = await _post<Map<String, dynamic>>(
        '/auth/refresh/',
        {'refresh': refresh},
        (json) => json,
      );
      final newAccess = res['access'] as String?;
      final newRefresh = res['refresh'] as String?;
      if (newAccess != null) {
        _token = newAccess;
        await _tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh ?? refresh,
        );
        _log('Token refresh successful');
        return newAccess;
      }
    } catch (e) {
      _log('Token refresh failed: $e');
    }
    return null;
  }

  Future<Shop> getMyShop() async {
    return _get<Shop>('/shops/my_shop/', (json) => Shop.fromJson(json));
  }

  Future<Shop> updateMyShop(Map<String, dynamic> body) async {
    return _patch<Shop>('/shops/my_shop/', body, (json) => Shop.fromJson(json));
  }

  Future<DashboardData> getDashboard() async {
    return _get<DashboardData>('/shops/dashboard/', (json) => DashboardData.fromJson(json));
  }

  Future<List<Worker>> getWorkers() async {
    return _getList<Worker>('/workers/', (json) => Worker.fromJson(json));
  }

  Future<Worker> createWorker(Map<String, dynamic> body) async {
    return _post<Worker>('/workers/', body, (json) => Worker.fromJson(json));
  }

  Future<Worker> updateWorker(int id, Map<String, dynamic> body) async {
    return _patch<Worker>('/workers/$id/', body, (json) => Worker.fromJson(json));
  }

  Future<void> deleteWorker(int id) async {
    await _delete('/workers/$id/');
  }

  Future<List<Product>> getProducts() async {
    return _getList<Product>('/products/', (json) => Product.fromJson(json));
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    return _post<Product>('/products/', body, (json) => Product.fromJson(json));
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> body) async {
    return _patch<Product>('/products/$id/', body, (json) => Product.fromJson(json));
  }

  Future<void> deleteProduct(int id) async {
    await _delete('/products/$id/');
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
    return _post<Map<String, dynamic>>('/billing/invoices/', body, (json) => json);
  }

  Future<List<dynamic>> getInvoices() async {
    return _getList<dynamic>('/billing/invoices/', (json) => json);
  }

  Future<Map<String, dynamic>> getInvoice(int id) async {
    return _get<Map<String, dynamic>>('/billing/invoices/$id/', (json) => json);
  }

  Future<List<Offer>> getOffers() async {
    return _getList<Offer>('/offers/', (json) => Offer.fromJson(json));
  }

  Future<Offer> createOffer(Map<String, dynamic> body) async {
    return _post<Offer>('/offers/', body, (json) => Offer.fromJson(json));
  }

  Future<List<Announcement>> getAnnouncements() async {
    return _getList<Announcement>('/announcements/', (json) => Announcement.fromJson(json));
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> body) async {
    return _post<Announcement>('/announcements/', body, (json) => Announcement.fromJson(json));
  }

  Future<Offer> updateOffer(int id, Map<String, dynamic> body) async {
    return _patch<Offer>('/offers/$id/', body, (json) => Offer.fromJson(json));
  }

  Future<void> deleteOffer(int id) async {
    await _delete('/offers/$id/');
  }

  Future<Announcement> updateAnnouncement(int id, Map<String, dynamic> body) async {
    return _patch<Announcement>('/announcements/$id/', body, (json) => Announcement.fromJson(json));
  }

  Future<void> deleteAnnouncement(int id) async {
    await _delete('/announcements/$id/');
  }

  Future<List<StockAdjustment>> getStockAdjustments() async {
    return _getList<StockAdjustment>('/inventory/', (json) => StockAdjustment.fromJson(json));
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
    return _post<StockAdjustment>('/inventory/', body, (json) => StockAdjustment.fromJson(json));
  }

  // ============ Core HTTP Methods ============

  Future<T> _get<T>(String path, T Function(dynamic) fromJson) async {
    return _request<T>(
      () => _client.get(
        Uri.parse('${_config.baseUrl}$path'),
        headers: _headers(),
      ),
      fromJson,
      isSafeMethod: true,
    );
  }

  Future<T> _post<T>(String path, Map<String, dynamic> body, T Function(dynamic) fromJson) async {
    return _request<T>(
      () => _client.post(
        Uri.parse('${_config.baseUrl}$path'),
        headers: _headers(),
        body: jsonEncode(body),
      ),
      fromJson,
      isSafeMethod: false,
    );
  }

  Future<T> _patch<T>(String path, Map<String, dynamic> body, T Function(dynamic) fromJson) async {
    return _request<T>(
      () => _client.patch(
        Uri.parse('${_config.baseUrl}$path'),
        headers: _headers(),
        body: jsonEncode(body),
      ),
      fromJson,
      isSafeMethod: false,
    );
  }

  Future<void> _delete(String path) async {
    await _request<void>(
      () => _client.delete(
        Uri.parse('${_config.baseUrl}$path'),
        headers: _headers(),
      ),
      (_) => null,
      isSafeMethod: false,
    );
  }

  /// Core request method with timeout, error parsing, token refresh, and safe retries.
  Future<T> _request<T>(
    Future<http.Response> Function() requestFn,
    T Function(dynamic) fromJson, {
    required bool isSafeMethod,
    int retryCount = 0,
  }) async {
    http.Response? res;
    try {
      res = await requestFn().timeout(_config.requestTimeout);
    } on TimeoutException catch (e) {
      _log('Request timeout: $e');
      throw ApiException('Request timed out', statusCode: 408, errorCode: 'TIMEOUT');
    } on SocketException catch (e) {
      _log('Network error: $e');
      throw ApiException('Network error: ${e.message}', statusCode: 503, errorCode: 'NETWORK_ERROR');
    } on FormatException catch (e) {
      _log('Invalid response format: $e');
      throw ApiException('Invalid response format', statusCode: 500, errorCode: 'FORMAT_ERROR');
    } catch (e) {
      _log('Unexpected error: $e');
      throw ApiException('Unexpected error: $e', statusCode: 500, errorCode: 'UNKNOWN_ERROR');
    }

    _log('Response ${res.statusCode} for ${res.request?.url}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final json = _parseJson(res);
      return fromJson(json);
    }

    if (res.statusCode == 204) {
      return fromJson(null as dynamic);
    }

    if (res.statusCode == 401 && retryCount < 1) {
      _log('Received 401, attempting token refresh (retry $retryCount)');
      final newToken = await refreshToken();
      if (newToken != null) {
        return _request<T>(requestFn, fromJson, isSafeMethod: true, retryCount: retryCount + 1);
      } else {
        await clearTokens();
        throw ApiException('Session expired. Please log in again.', statusCode: 401, errorCode: 'SESSION_EXPIRED');
      }
    }

    // Handle specific error codes
    final errorData = _parseJson(res);
    final message = errorData is Map ? (errorData['detail'] ?? errorData['message'] ?? 'Request failed') : 'Request failed';
    final errorCode = errorData is Map ? errorData['code'] as String? : null;

    if (res.statusCode == 409) {
      throw ApiException(message, statusCode: 409, errorCode: errorCode ?? 'CONFLICT');
    }
    if (res.statusCode == 403) {
      throw ApiException(message, statusCode: 403, errorCode: errorCode ?? 'FORBIDDEN');
    }
    if (res.statusCode == 404) {
      throw ApiException(message, statusCode: 404, errorCode: errorCode ?? 'NOT_FOUND');
    }
    if (res.statusCode >= 500) {
      throw ApiException(message, statusCode: res.statusCode, errorCode: errorCode ?? 'SERVER_ERROR');
    }

    throw ApiException(message, statusCode: res.statusCode, errorCode: errorCode);
  }

  dynamic _parseJson(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } on FormatException {
      return res.body;
    }
  }

  Future<List<T>> _getList<T>(String path, T Function(dynamic) fromJson) async {
    return _request<List<T>>(
      () => _client.get(
        Uri.parse('${_config.baseUrl}$path'),
        headers: _headers(),
      ),
      (json) {
        if (json is Map && json['results'] is List) {
          return (json['results'] as List).map((e) => fromJson(e)).toList();
        } else if (json is List) {
          return json.map((e) => fromJson(e)).toList();
        }
        return <T>[];
      },
      isSafeMethod: true,
    );
  }

  void close() => _client.close();
}

/// Debug print that respects release mode
void debugPrint(String message) {
  if (!bool.fromEnvironment('dart.vm.product')) {
    // Only log in debug mode
    // ignore: avoid_print
    print(message);
  }
}