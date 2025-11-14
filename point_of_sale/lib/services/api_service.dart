import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  String get baseUrl => 'http://10.0.2.2:8000/api';
  // String get baseUrl => 'http://localhost:8000/api';

  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verify2FA(String userId, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-2fa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'otp': otp}),
    );

    return jsonDecode(res.body);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<List<dynamic>> getProducts() async {
    final token = await getToken();
    print(token);
    final url = Uri.parse("$baseUrl/products");

    final res = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    // print("STATUS: ${res.statusCode}");
    // print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Error: ${res.body}");
  }

  Future<bool> createOrder({
    int? customerId,
    String? customerName, // opsional, bisa null
    required List cart,
    // List cart dari POSPage
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/orders'); // endpoint sesuai apiResource
    final res = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "customer_id": customerId,
        "customer_name": customerName, // <-- tambahkan parameter customerName
        "items": cart
            .map((c) => {"product_id": c['id'], "quantity": c['qty']})
            .toList(),
      }),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> logout(String token) async {
    final url = Uri.parse('$baseUrl/logout');
    await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }

  // Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> data) async {
  //   final token = await getToken();
  //   final res = await http.post(
  //     Uri.parse('$baseUrl/products'),
  //     headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  //     body: jsonEncode(data),
  //   );
  //   if (res.statusCode == 201 || res.statusCode == 200)
  //     return jsonDecode(res.body);
  //   return null;
  // }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/products');
    try {
      final res = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": data['name'],
          "description": data['description'] ?? "",
          "price": data['price'] ?? 0,
          "stock": data['stock'] ?? 0,
          "category_id": data['category_id'], // optional
        }),
      );
      debugPrint('Create product response: ${res.body}');

      // if (res.statusCode == 200 || res.statusCode == 201) {
      return true;
      // } else {
      //   debugPrint('Create product failed: ${res.body}');
      //   return false;
      //    }
    } catch (e) {
      debugPrint('Create product error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print('URL: $baseUrl/products/$id');
    print('Body: ${jsonEncode(data)}');
    print('Status: ${res.statusCode}');
    print('Response: ${res.body}');

    if (res.statusCode == 200) return jsonDecode(res.body);

    return null;
  }

  Future<bool> deleteProduct(int id) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return res.statusCode == 200;
  }

  Future<List> getCategories() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/category');
    final res = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    }
    return [];
  }

  // Buat kategori baru
  Future<Map?> createCategory(Map data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/categories');
    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // Update kategori
  Future<Map?> updateCategory(int id, Map data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/categories/$id');
    final res = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // Hapus kategori
  Future<bool> deleteCategory(int id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/categories/$id');
    final res = await http.delete(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return res.statusCode == 200;
  }

  // SUPPLIERS
  Future<List<dynamic>?> getSuppliers() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/suppliers'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    print('Get suppliers error: ${res.body}');
    return null;
  }

  Future<Map<String, dynamic>?> createSupplier(
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/suppliers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    print('Create supplier error: ${res.body}');
    return null;
  }

  Future<Map<String, dynamic>?> updateSupplier(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/suppliers/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    print('Update supplier error: ${res.body}');
    return null;
  }

  Future<bool> deleteSupplier(int id) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/suppliers/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  Future<List<dynamic>?> getPurchaseOrders({int? supplierId}) async {
    final token = await getToken();
    String url = '$baseUrl/purchase-orders';
    if (supplierId != null) {
      url += '?supplier_id=$supplierId';
    }

    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    print('Get purchase orders error: ${res.body}');
    return null;
  }

  Future<bool> postPurchaseOrder(Map<String, dynamic> data) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/purchase-orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print('POST purchase-orders => ${res.statusCode}');
    print('Response: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return true;
    }

    print('Error creating purchase order: ${res.body}');
    return false;
  }

  Future<bool> updatePurchaseOrder(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/purchase-orders/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 200) return true;
    print('Update purchase order error: ${res.body}');
    return false;
  }

  Future<bool> deletePurchaseOrder(int id) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/purchase-orders/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200 || res.statusCode == 204) return true;
    print('Delete purchase order error: ${res.body}');
    return false;
  }

  Future<bool> createStockHistory({
    required int productId,
    required int change,
    required String type,
    String? note,
  }) async {
    final token = await getToken();
    final payload = {
      'product_id': productId,
      'change': change,
      'type': type, // in, out, adjustment, opname
      'note': note,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/inventory'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('[POST] /inventory => ${res.statusCode}');
    print('Payload: $payload');
    print('Response: ${res.body}');

    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> updateStockHistory(
    int id, {
    required int change,
    required String type,
    String? note,
  }) async {
    final token = await getToken();
    final payload = {'change': change, 'type': type, 'note': note};

    final res = await http.put(
      Uri.parse('$baseUrl/inventory/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('[PUT] /inventory/$id => ${res.statusCode}');
    print('Payload: $payload');
    print('Response: ${res.body}');

    return res.statusCode == 200;
  }

  Future<bool> deleteStockHistory(int id) async {
    final token = await getToken();

    final res = await http.delete(
      Uri.parse('$baseUrl/inventory/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    print('[DELETE] /inventory/$id => ${res.statusCode}');
    print('Response: ${res.body}');

    return res.statusCode == 200 || res.statusCode == 204;
  }

  Future<List<dynamic>> getInventoryHistory() async {
    final token = await getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/inventory'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    print('[GET] /inventory => ${res.statusCode}');
    print('Response: ${res.body}');

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['data'];
    }

    return [];
  }

  // UPDATE STOCK (+/-)
  Future<bool> updateStock(int productId, int value) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/update-stock'),
        body: {'product_id': productId.toString(), 'change': value.toString()},
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // STOCK OPNAME (set stok langsung)
  Future<bool> stockOpname(int productId, int actualStock) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/stock-opname'),
        body: {
          'product_id': productId.toString(),
          'stock': actualStock.toString(),
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print(response.body);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List> getOrdersHistory() async {
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['data'] ?? [];
      }

      return []; // jika status bukan 200
    } catch (e) {
      print("Error getOrdersHistory: $e");
      return []; // jika error tetap return list kosong
    }
  }
}
