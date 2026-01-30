import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:restaurant_kiosco/models/modifiers.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../constants.dart';


class ApiService {

  // Método para obtener todas las categorías
  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else { 
      throw Exception('Error al cargar las categorías');
    }
  }

  // Método para obtener una categoría con productGroups y products
  static Future<Category> fetchCategoryWithProducts(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return Category.fromJson(json);
    } else {
      throw Exception('Error al cargar la categoría con productos');
    }
  }

  static Future<List<ModifierGroup>> fetchModifierGroups(int productId) async {
    final url = Uri.parse('$baseUrl/products/$productId/modifiers/grouped');
    final res = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }

    final List data = jsonDecode(res.body);
    return data.map((g) => ModifierGroup.fromJson(g)).toList();
  }

  // Método para obtener órdenes de cocina
  static Future<KitchenResponse> fetchKitchenOrders({
    required int restaurantId,
    String? since,
    String? status,
  }) async {
    final params = {
      'restaurant_id': restaurantId.toString(),
      if (since != null) 'since': since,
      if (status != null) 'status': status,
    };
    
    final url = Uri.parse('$baseUrl/kitchen/orders').replace(queryParameters: params);
    final res = await http.get(url, headers: {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }

    return KitchenResponse.fromJson(jsonDecode(res.body));
  }

  // Método para actualizar el estado de una orden
  static Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/kitchen/orders/$orderId/status');
    final res = await http.patch(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  // Método para crear una orden desde el kiosko
  static Future<Map<String, dynamic>> createOrder({
    required int restaurantId,
    String? clientName,
    String? clientPhone,
    String? paymentMethod, // Optional for Open Tabs
    int? tableId,
    required List<Map<String, dynamic>> items,
    required double total,
    double tip = 0.0,
  }) async {
    final url = Uri.parse('$baseUrl/orders');
    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'restaurant_id': restaurantId,
        'client_name': clientName,
        'client_phone': clientPhone,
        'payment_method': paymentMethod, // Can be null
        'table_id': tableId,
        'items': items,
        'total': total,
        'tip': tip,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Error al crear orden: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('Error: ${data['message']}');
    }

    return data['data'];
  }

  // Método para obtener información de un restaurante
  static Future<Restaurant> fetchRestaurant(int restaurantId) async {
    final url = Uri.parse('$baseUrl/restaurants/$restaurantId');
    final res = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('Error: ${data['message']}');
    }

    return Restaurant.fromJson(data['data']);
  }

  // Método para obtener restaurantes de un tenant
  static Future<List<Restaurant>> fetchTenantRestaurants(int tenantId) async {
    final url = Uri.parse('$baseUrl/tenants/$tenantId/restaurants');
    final res = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('Error: ${data['message']}');
    }

    final List restaurantsData = data['data'];
    return restaurantsData.map((json) => Restaurant.fromJson(json)).toList();
  }

  // Método para pagar una orden existente
  static Future<void> payOrder({
    required int orderId,
    required String paymentMethod,
    double? tip,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/pay');
    final res = await http.patch(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'payment_method': paymentMethod,
        'tip': tip,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Error al pagar orden: ${res.body}');
    }
  }
}
