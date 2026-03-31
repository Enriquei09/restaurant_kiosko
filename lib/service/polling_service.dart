import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'api_service.dart';

class PollingService {
  Timer? _timer;
  int _restaurantId = 1;
  
  // Notificador: La UI escuchará esta lista para redibujarse
  static final ValueNotifier<List<dynamic>> pendingOrders = ValueNotifier([]);

  /// Configurar el restaurante para el polling.
  void setRestaurantId(int id) {
    _restaurantId = id;
  }

  // Iniciar el ciclo (Polling)
  void startPolling() {
    debugPrint("🔄 Iniciando Polling de Órdenes (Cada 10s)...");
    
    // 1. Ejecutar inmediatamente al abrir la pantalla
    _fetchOrders();

    // 2. Repetir cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrders();
    });
  }

  // Detener el ciclo (al salir de la pantalla)
  void stopPolling() {
    _timer?.cancel();
    debugPrint("🛑 Polling detenido.");
  }

  Future<void> _fetchOrders() async {
    try {
      // Usar la misma ruta que el backend: /kitchen/orders
      final url = Uri.parse('$baseUrl/kitchen/orders?restaurant_id=$_restaurantId');
      debugPrint("📡 Consultando Kitchen: $url");
      
      final response = await http.get(
        url,
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> orders = [];

        // Manejo de formatos de Laravel
        if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is Map && data.containsKey('orders')) {
            orders = data['orders'] as List? ?? [];
          } else if (data is List) {
            orders = data;
          }
        } else if (decoded is List) {
          orders = decoded;
        }

        // Actualizamos la UI
        pendingOrders.value = orders;
        
        if (orders.isNotEmpty) {
           debugPrint("📦 Órdenes recuperadas: ${orders.length}");
        }

      } else {
        debugPrint("⚠️ Error API Polling: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error conexión Polling: $e");
    }
  }

  // Método para completar orden
  Future<bool> markOrderAsCompleted(int orderId) async {
    try {
      // Usar la ruta correcta: /kitchen/orders/{id}/status
      final url = Uri.parse('$baseUrl/kitchen/orders/$orderId/status');
      
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          ...ApiService.headers,
        },
        body: jsonEncode({"status": "ready"}),
      );

      if (response.statusCode == 200) {
        List<dynamic> currentOrders = List.from(pendingOrders.value);
        currentOrders.removeWhere((order) => order['id'] == orderId);
        pendingOrders.value = currentOrders;
        
        return true;
      } else {
        debugPrint("⚠️ Error al completar orden: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error de conexión: $e");
      return false;
    }
  }
}