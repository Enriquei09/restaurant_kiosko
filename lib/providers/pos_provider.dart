import 'package:flutter/material.dart';
import '../models/cash_register.dart';
import '../models/cash_register_terminal.dart';

class PosProvider with ChangeNotifier {
  // Información del tenant y restaurante (valores por defecto)
  int _tenantId = 1;
  int _restaurantId = 1;
  int? _locationId; // null por defecto — la tabla locations puede estar vacía
  int _userId = 1;

  // Caja actual
  CashRegister? _currentCashRegister;
  CashRegisterTerminal? _selectedTerminal;

  // Getters
  int get tenantId => _tenantId;
  int get restaurantId => _restaurantId;
  int? get locationId => _locationId;
  int get userId => _userId;
  CashRegister? get currentCashRegister => _currentCashRegister;
  CashRegisterTerminal? get selectedTerminal => _selectedTerminal;

  bool get hasOpenCashRegister => _currentCashRegister != null;

  // Setters
  void setTenantId(int tenantId) {
    _tenantId = tenantId;
    notifyListeners();
  }

  void setRestaurantId(int restaurantId) {
    _restaurantId = restaurantId;
    notifyListeners();
  }

  void setLocationId(int? locationId) {
    _locationId = locationId;
    notifyListeners();
  }

  void setUserId(int userId) {
    _userId = userId;
    notifyListeners();
  }

  void setSelectedTerminal(CashRegisterTerminal terminal) {
    _selectedTerminal = terminal;
    notifyListeners();
  }

  void setCurrentCashRegister(CashRegister? cashRegister) {
    _currentCashRegister = cashRegister;
    notifyListeners();
  }

  void clearSession() {
    _currentCashRegister = null;
    _selectedTerminal = null;
    notifyListeners();
  }

  // Información consolidada para APIs
  Map<String, dynamic> getSessionData() {
    return {
      'tenant_id': _tenantId,
      'restaurant_id': _restaurantId,
      'location_id': _locationId,
      'user_id': _userId,
      'cash_register_id': _currentCashRegister?.id,
      'terminal_id': _selectedTerminal?.id,
    };
  }
}