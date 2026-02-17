import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:restaurant_kiosco/models/modifiers.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/models/promotion.dart';
import 'package:restaurant_kiosco/models/screensaver_config.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../constants.dart';


class ApiService {

  // ── Token de autenticación global ─────────────────────────
  static String _authToken = '';

  /// Configurar el token de autenticación para todas las requests.
  static void setAuthToken(String token) {
    _authToken = token;
  }

  /// Headers base para todas las requests.
  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
  };

  /// Headers solo para GET (sin Content-Type).
  static Map<String, String> get _getHeaders => {
    'Accept': 'application/json',
    if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
  };

  // ==================== AUTH ====================

  /// Login con PIN — retorna token + usuario con rol y permisos.
  static Future<Map<String, dynamic>> loginByPin({
    required String pin,
    required int restaurantId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login-pin');
    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pin': pin,
        'restaurant_id': restaurantId,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      final error = jsonDecode(res.body);
      return {
        'success': false,
        'message': error['message'] ?? 'PIN inválido',
      };
    } else {
      throw Exception('Error de autenticación: ${res.statusCode}');
    }
  }

  /// Logout — revocar token.
  static Future<void> logout() async {
    final url = Uri.parse('$baseUrl/auth/logout');
    await http.post(url, headers: _headers);
  }

  /// Obtener datos del usuario autenticado.
  static Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('No autenticado');
    }
  }

  // ==================== CATEGORIES ====================
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
    final response = await http.get(Uri.parse('$baseUrl/categories/$id'), headers: _getHeaders);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return Category.fromJson(json);
    } else {
      throw Exception('Error al cargar la categoría con productos');
    }
  }

  static Future<List<ModifierGroup>> fetchModifierGroups(int productId) async {
    final url = Uri.parse('$baseUrl/products/$productId/modifiers/grouped');
    final res = await http.get(url, headers: _getHeaders);

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
    final res = await http.get(url, headers: _getHeaders);

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
      headers: _headers,
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
    int? cashRegisterId, // Caja que registra la orden
    int? waiterId, // Mesero responsable
    required List<Map<String, dynamic>> items,
    required double total,
    double tip = 0.0,
  }) async {
    final url = Uri.parse('$baseUrl/orders');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'restaurant_id': restaurantId,
        'client_name': clientName,
        'client_phone': clientPhone,
        'payment_method': paymentMethod, // Can be null
        'table_id': tableId,
        'cash_register_id': cashRegisterId, // Asignar caja al crear
        'waiter_id': waiterId, // Mesero responsable
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
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('Error: ${data['message']}');
    }

    return Restaurant.fromJson(data['data']);
  }

  // Obtener configuración/settings de un restaurante
  static Future<Map<String, dynamic>> fetchRestaurantSettings(int restaurantId) async {
    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/settings');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('Error: ${data['message']}');
    }

    return data['data'] as Map<String, dynamic>;
  }

  // Método para obtener restaurantes de un tenant
  static Future<List<Restaurant>> fetchTenantRestaurants(int tenantId) async {
    final url = Uri.parse('$baseUrl/tenants/$tenantId/restaurants');
    final res = await http.get(url, headers: _getHeaders);

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
    int? cashRegisterId,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/pay');
    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({
        'payment_method': paymentMethod,
        'tip': tip,
        'cash_register_id': cashRegisterId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Error al pagar orden: ${res.body}');
    }
  }

  // Obtener orden actual de una mesa
  static Future<Map<String, dynamic>?> getTableCurrentOrder(int tableId) async {
    final url = Uri.parse('$baseUrl/orders/table/$tableId/current');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['success'] ? data['data'] : null;
    } else if (res.statusCode == 404) {
      return null; // No hay orden activa
    }
    throw Exception('Error al obtener orden de mesa: ${res.body}');
  }

  // Obtener órdenes pendientes de pago (para cashier)
  static Future<List<Map<String, dynamic>>> fetchPendingPaymentOrders(int restaurantId) async {
    final url = Uri.parse('$baseUrl/orders?restaurant_id=$restaurantId&payment_status=pending');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode != 200) {
      throw Exception('Error al obtener órdenes pendientes: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception('Error: ${data['message']}');
    }

    return List<Map<String, dynamic>>.from(data['data']);
  }

  // Agregar items a orden existente
  static Future<Map<String, dynamic>> addItemsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/add-items');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'items': items}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Error al agregar items: ${res.body}');
  }

  // ==================== CASH REGISTER ====================

  /// Obtener caja actual del usuario
  static Future<Map<String, dynamic>> getCurrentCashRegister({
    required int userId,
    required int restaurantId,
  }) async {
    final url = Uri.parse('$baseUrl/cash-registers/current');
    final res = await http.get(
      url.replace(queryParameters: {
        'user_id': userId.toString(),
        'restaurant_id': restaurantId.toString(),
      }),
      headers: _getHeaders,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener caja actual: ${res.body}');
    }
  }

  /// Abrir caja
  static Future<Map<String, dynamic>> openCashRegister({
    required int tenantId,
    required int restaurantId,
    int? locationId,
    required int userId,
    int? terminalId,
    required double openingBalance,
    String? openingNotes,
    Map<String, dynamic>? denominationDetails,
  }) async {
    final url = Uri.parse('$baseUrl/cash-registers/open');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'tenant_id': tenantId,
        'restaurant_id': restaurantId,
        'location_id': locationId,
        'user_id': userId,
        'terminal_id': terminalId,
        'opening_balance': openingBalance,
        'opening_notes': openingNotes,
        'denomination_details': denominationDetails,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al abrir caja: ${res.body}');
    }
  }

  /// Obtener terminales disponibles
  static Future<Map<String, dynamic>> getTerminals({
    required int tenantId,
    required int restaurantId,
  }) async {
    final url = Uri.parse('$baseUrl/cash-registers/terminals?tenant_id=$tenantId&restaurant_id=$restaurantId');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener terminales: ${res.body}');
    }
  }

  /// Autenticar terminal con PIN
  static Future<Map<String, dynamic>> authenticateTerminalPin({
    required int tenantId,
    required int restaurantId,
    required String terminalNumber,
    required String pin,
  }) async {
    final url = Uri.parse('$baseUrl/cash-registers/authenticate-pin');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'tenant_id': tenantId,
        'restaurant_id': restaurantId,
        'terminal_number': terminalNumber,
        'pin': pin,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final errorData = jsonDecode(res.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'PIN incorrecto',
      };
    }
  }

  /// Cerrar caja
  static Future<Map<String, dynamic>> closeCashRegister({
    required int cashRegisterId,
    required double closingBalance,
    String? closingNotes,
    Map<String, dynamic>? denominationDetails,
  }) async {
    final url = Uri.parse('$baseUrl/cash-registers/$cashRegisterId/close');
    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({
        'closing_balance': closingBalance,
        'closing_notes': closingNotes,
        'denomination_details': denominationDetails,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al cerrar caja: ${res.body}');
    }
  }

  /// Obtener reporte de caja
  static Future<Map<String, dynamic>> getCashRegisterReport(
      int cashRegisterId) async {
    final url = Uri.parse('$baseUrl/cash-registers/$cashRegisterId/report');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener reporte: ${res.body}');
    }
  }

  // ==================== SUPERVISOR AUTH ====================

  /// Verificar PIN de supervisor
  static Future<Map<String, dynamic>> verifySupervisorPin({
    required String pin,
    required int restaurantId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-supervisor');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'pin': pin,
        'restaurant_id': restaurantId,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'PIN inválido');
    } else {
      throw Exception('Error al verificar PIN: ${res.body}');
    }
  }

  // ==================== MULTIPLE PAYMENTS ====================

  /// Procesar múltiples pagos para una orden
  static Future<Map<String, dynamic>> processMultiplePayments({
    required int orderId,
    required List<Map<String, dynamic>> payments,
    double? tip,
    int? cashRegisterId,
  }) async {
    final url = Uri.parse('$baseUrl/payments/orders/$orderId/process');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'payments': payments,
        'tip': tip,
        'cash_register_id': cashRegisterId,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al procesar pagos: ${res.body}');
    }
  }

  /// Obtener pagos de una orden
  static Future<Map<String, dynamic>> getOrderPayments(int orderId) async {
    final url = Uri.parse('$baseUrl/payments/orders/$orderId');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener pagos: ${res.body}');
    }
  }

  // ============================================================================
  // DESCUENTOS (Discounts)
  // ============================================================================

  /// Aplicar descuento a una orden
  static Future<Map<String, dynamic>> applyDiscount({
    required int orderId,
    required int appliedBy,
    required String type,
    required double value,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/discounts/orders/$orderId');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'applied_by': appliedBy,
        'type': type,
        'value': value,
        'reason': reason,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al aplicar descuento: ${res.body}');
    }
  }

  /// Autorizar descuento
  static Future<Map<String, dynamic>> authorizeDiscount({
    required int discountId,
    required int supervisorId,
  }) async {
    final url = Uri.parse('$baseUrl/discounts/$discountId/authorize');
    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'supervisor_id': supervisorId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al autorizar descuento: ${res.body}');
    }
  }

  /// Obtener descuentos pendientes
  static Future<Map<String, dynamic>> getPendingDiscounts() async {
    final url = Uri.parse('$baseUrl/discounts/pending');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener descuentos pendientes: ${res.body}');
    }
  }

  // ============================================================================
  // DEVOLUCIONES (Refunds)
  // ============================================================================

  /// Crear devolución
  static Future<Map<String, dynamic>> createRefund({
    required int orderId,
    int? orderDetailId,
    required double amount,
    required String reason,
    required int processedBy,
    required String refundMethod,
  }) async {
    final url = Uri.parse('$baseUrl/refunds');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'order_id': orderId,
        'order_detail_id': orderDetailId,
        'amount': amount,
        'reason': reason,
        'processed_by': processedBy,
        'refund_method': refundMethod,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al crear devolución: ${res.body}');
    }
  }

  /// Autorizar devolución
  static Future<Map<String, dynamic>> authorizeRefund({
    required int refundId,
    required int supervisorId,
  }) async {
    final url = Uri.parse('$baseUrl/refunds/$refundId/authorize');
    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'supervisor_id': supervisorId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al autorizar devolución: ${res.body}');
    }
  }

  /// Completar devolución
  static Future<Map<String, dynamic>> completeRefund(int refundId) async {
    final url = Uri.parse('$baseUrl/refunds/$refundId/complete');
    final res = await http.patch(url, headers: _headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al completar devolución: ${res.body}');
    }
  }

  /// Obtener devoluciones pendientes
  static Future<Map<String, dynamic>> getPendingRefunds() async {
    final url = Uri.parse('$baseUrl/refunds/pending');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener devoluciones pendientes: ${res.body}');
    }
  }

  /// Obtener devoluciones de una orden
  static Future<Map<String, dynamic>> getOrderRefunds(int orderId) async {
    final url = Uri.parse('$baseUrl/refunds/orders/$orderId');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener devoluciones: ${res.body}');
    }
  }

  // ============================================================================
  // ANULACIONES Y CORTESÍAS (Voids & Courtesies)
  // ============================================================================

  /// Anular orden
  static Future<Map<String, dynamic>> voidOrder({
    required int orderId,
    required int supervisorId,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/void');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'supervisor_id': supervisorId,
        'reason': reason,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al anular orden: ${res.body}');
    }
  }

  /// Marcar item como cortesía
  static Future<Map<String, dynamic>> markItemAsCourtesy({
    required int orderId,
    required int detailId,
    required int supervisorId,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/items/$detailId/courtesy');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'supervisor_id': supervisorId,
        'reason': reason,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al marcar como cortesía: ${res.body}');
    }
  }

  // ==================== MENÚ COMPLETO ====================

  /// Obtener el menú completo del restaurante (categorías → subcategorías → productos + promos).
  static Future<List<Map<String, dynamic>>> fetchMenu(int restaurantId) async {
    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/menu');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    } else {
      throw Exception('Error al cargar el menú: ${res.statusCode}');
    }
  }

  // ==================== PROMOCIONES ====================

  /// Obtener promociones activas del restaurante.
  static Future<List<Promotion>> fetchActivePromotions(int restaurantId) async {
    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/promotions');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body['data'] as List? ?? [];
      return list.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar promociones: ${res.statusCode}');
    }
  }

  /// Validar carrito contra promociones.
  static Future<CartPromotionResult> validateCartPromotions({
    required int restaurantId,
    required List<Map<String, dynamic>> items,
    int? userId,
  }) async {
    final url = Uri.parse('$baseUrl/promotions/validate-cart');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'restaurant_id': restaurantId,
        'items': items,
        if (userId != null) 'user_id': userId,
      }),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return CartPromotionResult.fromJson(body['data']);
    } else {
      throw Exception('Error al validar promociones: ${res.body}');
    }
  }

  /// Aplicar promociones a una orden (registrar uso).
  static Future<Map<String, dynamic>> applyPromotions({
    required int orderId,
    required List<Map<String, dynamic>> promotions,
    int? userId,
  }) async {
    final url = Uri.parse('$baseUrl/promotions/apply');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'order_id': orderId,
        'promotions': promotions,
        if (userId != null) 'user_id': userId,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al aplicar promociones: ${res.body}');
    }
  }

  // ==================== SCREENSAVER ====================

  /// Obtener configuración e imágenes del screensaver.
  static Future<ScreensaverConfig> fetchScreensaver(int restaurantId) async {
    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/screensaver');
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return ScreensaverConfig.fromJson(body['data']);
    } else {
      throw Exception('Error al cargar screensaver: ${res.statusCode}');
    }
  }

  // ==================== TABLES ====================

  /// Obtener lista de mesas de un restaurante (con estado).
  static Future<List<Map<String, dynamic>>> fetchTables(int restaurantId, {int? locationId}) async {
    final queryParams = {
      'restaurant_id': restaurantId.toString(),
      if (locationId != null) 'location_id': locationId.toString(),
    };
    final url = Uri.parse('$baseUrl/tables').replace(queryParameters: queryParams);
    final res = await http.get(url, headers: _getHeaders);

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception('Error al cargar mesas: ${res.statusCode}');
    }
  }

  /// Actualizar estado de una mesa (available, occupied, reserved, etc.).
  static Future<Map<String, dynamic>> updateTableStatus(int tableId, String status) async {
    final url = Uri.parse('$baseUrl/tables/$tableId');
    final res = await http.put(
      url,
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al actualizar mesa: ${res.statusCode}');
    }
  }
}