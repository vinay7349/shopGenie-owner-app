import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  String? _token;

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

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access'] ?? data['tokens']?['access'];
      return data;
    } else {
      throw Exception('Login failed: ${res.body}');
    }
  }

  Future<Shop> getMyShop() async {
    final res = await http.get(Uri.parse('$baseUrl/shops/my_shop/'), headers: _headers());
    if (res.statusCode == 200) {
      return Shop.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load shop');
  }

  Future<Shop> updateMyShop(Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/shops/my_shop/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Shop.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to update shop');
  }

  Future<List<Worker>> getWorkers() async {
    final res = await http.get(Uri.parse('$baseUrl/workers/'), headers: _headers());
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Worker.fromJson(e)).toList();
    }
    throw Exception('Failed to load workers');
  }

  Future<Worker> createWorker(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/workers/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Worker.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to create worker: ${res.body}');
  }

  Future<Worker> updateWorker(int id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/workers/$id/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Worker.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to update worker: ${res.body}');
  }

  Future<List<Product>> getProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products/'), headers: _headers());
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Failed to load products');
  }

  Future<Map<String, dynamic>> confirmBill({
    required List<InvoiceItem> items,
    required String paymentMode,
    String? customerName,
    String? customerPhone,
  }) async {
    final body = {
      'payment_mode': paymentMode,
      'customer_name': customerName ?? 'Walk-in Customer',
      'customer_phone': customerPhone ?? '',
      'items': items.map((i) => i.toJson()).toList(),
    };
    final res = await http.post(
      Uri.parse('$baseUrl/billing/invoices/'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Bill confirmation failed: ${res.body}');
  }
}
