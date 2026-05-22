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

  // Mesa seleccionada para la sesión de carrito
  int? _selectedTableId;
  int? get selectedTableId => _selectedTableId;

  void selectTable(int? id) {
    _selectedTableId = id;
    notifyListeners();
  }

  // ── Helpers internos ──────────────────────────────────────

  /// Reemplaza una mesa en la lista local por el JSON actualizado del API.
  void _applyTableUpdate(Map<String, dynamic> tableJson) {
    final updated = RestaurantTable.fromJson(tableJson);
    final idx = _tables.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _tables[idx] = updated;
      notifyListeners();
    }
  }

  // ── Fetch ─────────────────────────────────────────────────

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

  // ── Máquina de estados ────────────────────────────────────

  /// Abre una mesa libre (available → occupied).
  /// Actualiza la lista local con el estado rosa al instante.
  /// Devuelve la [RestaurantTable] actualizada o lanza [Exception].
  Future<RestaurantTable> openTable(int tableId) async {
    final result = await ApiService.openTable(tableId);
    // result = { table: {...}, order: {...} }
    final tableJson = result['table'] as Map<String, dynamic>;
    _applyTableUpdate(tableJson);
    return RestaurantTable.fromJson(tableJson);
  }

  /// Adquiere el lock de edición para el mesero actual (occupied → locked).
  /// Lanza [Exception] si otro mesero ya tiene el lock.
  Future<RestaurantTable> lockTable(int tableId) async {
    final tableJson = await ApiService.lockTable(tableId);
    _applyTableUpdate(tableJson);
    return RestaurantTable.fromJson(tableJson);
  }

  /// Libera el lock de edición al volver al mapa.
  Future<void> releaseLock(int tableId) async {
    try {
      final tableJson = await ApiService.releaseTableLock(tableId);
      _applyTableUpdate(tableJson);
    } catch (_) {
      // Silencioso: si falla el release no bloqueamos al mesero
    }
  }

  /// Congela la cuenta (occupied → bill_printed, tile azul).
  Future<RestaurantTable> printPreBill(int tableId) async {
    final tableJson = await ApiService.printPreBill(tableId);
    _applyTableUpdate(tableJson);
    return RestaurantTable.fromJson(tableJson);
  }

  // ── Legacy: actualización directa de status ───────────────

  Future<bool> updateTableStatus(int tableId, String status) async {
    try {
      final result = await ApiService.updateTableStatus(tableId, status);
      final idx = _tables.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        _tables[idx] = RestaurantTable.fromJson(result);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('updateTableStatus error: $e');
      return false;
    }
  }
}
