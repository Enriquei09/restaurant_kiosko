import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/table_model.dart';
import '../service/api_service.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _error;

  List<RestaurantTable> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String _baseUrl = 'http://127.0.0.1:8000/api'; // This should ideally come from config

  // Select a table for the current session (Cart)
  int? _selectedTableId;
  int? get selectedTableId => _selectedTableId;

  void selectTable(int? id) {
    _selectedTableId = id;
    notifyListeners();
  }

  Future<void> fetchTables(int restaurantId, {int? locationId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify start loading

    try {
      // Construct URL
      // Adjust standard URL based on whether we use ApiService or direct http
      // Assuming direct http for now or matching existing patterns
      final uri = Uri.parse('$_baseUrl/tables?restaurant_id=$restaurantId${locationId != null ? '&location_id=$locationId' : ''}');
      
      // In a real app we'd attach headers (auth token) here
      // Checking how other providers do it would be good, but standard approach:
      final response = await http.get(uri, headers: {
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token', 
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tables = data.map((json) => RestaurantTable.fromJson(json)).toList();
      } else {
        _error = 'Error fetching tables: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTableStatus(int tableId, String status) async {
      try {
          final uri = Uri.parse('$_baseUrl/tables/$tableId');
          final response = await http.put(uri, 
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'status': status})
          );
          
          if (response.statusCode == 200) {
              // Update local list
              final index = _tables.indexWhere((t) => t.id == tableId);
              if (index != -1) {
                  // Re-fetch or manually update? Manually update is faster UI
                  // But since RestaurantTable fields are final, we replace the object
                   // We need copyWith or just re-fetch. 
                   // Let's just re-fetch or assume success if critical.
                   // Ideally we parse the response.
                   final updated = RestaurantTable.fromJson(jsonDecode(response.body));
                   _tables[index] = updated;
                   notifyListeners();
              }
              return true;
          }
           return false;
      } catch (e) {
          print(e);
          return false;
      }
  }
}
