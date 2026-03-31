import 'package:flutter/material.dart';
import '../models/cash_register.dart';
import '../service/api_service.dart';

class CashRegisterProvider extends ChangeNotifier {
  CashRegister? _currentRegister;
  SalesSummary? _salesSummary;
  bool _isLoading = false;
  String? _error;

  CashRegister? get currentRegister => _currentRegister;
  SalesSummary? get salesSummary => _salesSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOpen => _currentRegister?.isOpen ?? false;
  bool get isClosed => _currentRegister?.isClosed ?? true;

  /// Cargar caja actual del usuario
  Future<void> loadCurrentRegister({
    required int userId,
    required int restaurantId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getCurrentCashRegister(
        userId: userId,
        restaurantId: restaurantId,
      );

      if (response['cash_register'] != null) {
        _currentRegister = CashRegister.fromJson(response['cash_register']);
        if (response['sales_summary'] != null) {
          _salesSummary = SalesSummary.fromJson(response['sales_summary']);
        }
      } else {
        _currentRegister = null;
        _salesSummary = null;
      }
    } catch (e) {
      _error = 'Error al cargar caja: $e';
      _currentRegister = null;
      _salesSummary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Abrir una nueva caja
  Future<bool> openRegister({
    required int tenantId,
    required int restaurantId,
    required int userId,
    required int terminalId,
    required double openingBalance,
    String? openingNotes,
    Map<String, dynamic>? denominationDetails,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.openCashRegister(
        tenantId: tenantId,
        restaurantId: restaurantId,
        userId: userId,
        terminalId: terminalId,
        openingBalance: openingBalance,
        openingNotes: openingNotes,
        denominationDetails: denominationDetails,
      );

      _currentRegister = CashRegister.fromJson(response['cash_register']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al abrir caja: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar caja actual
  Future<bool> closeRegister({
    required double closingBalance,
    String? closingNotes,
    Map<String, dynamic>? denominationDetails,
  }) async {
    if (_currentRegister == null) {
      _error = 'No hay caja abierta';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.closeCashRegister(
        cashRegisterId: _currentRegister!.id,
        closingBalance: closingBalance,
        closingNotes: closingNotes,
        denominationDetails: denominationDetails,
      );

      _currentRegister = CashRegister.fromJson(response['cash_register']);
      if (response['sales_summary'] != null) {
        _salesSummary = SalesSummary.fromJson(response['sales_summary']);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al cerrar caja: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener reporte de caja
  Future<Map<String, dynamic>?> getReport(int cashRegisterId) async {
    try {
      return await ApiService.getCashRegisterReport(cashRegisterId);
    } catch (e) {
      _error = 'Error al obtener reporte: $e';
      notifyListeners();
      return null;
    }
  }

  /// Limpiar estado
  void clear() {
    _currentRegister = null;
    _salesSummary = null;
    _error = null;
    notifyListeners();
  }
}
