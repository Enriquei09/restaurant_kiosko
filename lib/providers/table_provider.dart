import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../service/api_service.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _error;

  List<RestaurantTable> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    notifyListeners();

    try {
      final data = await ApiService.fetchTables(restaurantId, locationId: locationId);
      _tables = data.map((json) => RestaurantTable.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTableStatus(int tableId, String status) async {
    try {
      final result = await ApiService.updateTableStatus(tableId, status);
      
      // Update local list with the updated table
      final index = _tables.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final updated = RestaurantTable.fromJson(result);
        _tables[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
