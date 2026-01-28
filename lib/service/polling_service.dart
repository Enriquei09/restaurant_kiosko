import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart'; // O donde tengas tu 'baseUrl'

class PollingService {
  Timer? _timer;
  
  // Notificador: La UI escuchará esta lista para redibujarse
  static final ValueNotifier<List<dynamic>> pendingOrders = ValueNotifier([]);

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
      // URL sin query params - el shop_id va en el header
      final url = Uri.parse('$baseUrl/kds/orders/pending');
      debugPrint("📡 Consultando KDS: $url");
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'X-Shop-ID': '1',  // ID de la tienda
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> orders = [];

        // Manejo de formatos de Laravel (Lista pura vs { data: [] })
        if (decoded is List) {
          orders = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          orders = decoded['data'];
        }

        // Actualizamos la UI
        pendingOrders.value = orders;
        
        // (Opcional) Log para ver si llegan
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
      // Url de tu ruta PATCH
      final url = Uri.parse('$baseUrl/kds/orders/$orderId/status');
      
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'X-Shop-ID': '1',  // ID de la tienda
        },
        body: jsonEncode({"status": "completed"}), // O el estado que uses en tu DB
      );

      if (response.statusCode == 200) {
        // ✨ TRUCO DE UX:
        // Borramos la orden de la lista LOCALMENTE de inmediato
        // para que el cocinero sienta que la app es instantánea.
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