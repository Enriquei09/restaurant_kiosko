import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../service/api_service.dart';

class RestaurantProvider extends ChangeNotifier {
  int? _currentRestaurantId;
  int? _currentTenantId;
  Restaurant? _currentRestaurant;
  List<Restaurant> _availableRestaurants = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  int? get currentRestaurantId => _currentRestaurantId;
  int? get currentTenantId => _currentTenantId;
  Restaurant? get currentRestaurant => _currentRestaurant;
  List<Restaurant> get availableRestaurants => _availableRestaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelection => _currentRestaurantId != null && _currentTenantId != null;

  /// Inicializar desde SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentRestaurantId = prefs.getInt('selected_restaurant_id');
      _currentTenantId = prefs.getInt('selected_tenant_id');

      if (_currentRestaurantId != null && _currentTenantId != null) {
        await loadRestaurantData();
      }
    } catch (e) {
      _error = 'Error al inicializar: $e';
      debugPrint(_error);
    }
  }

  /// Seleccionar restaurante
  Future<void> selectRestaurant(int restaurantId, int tenantId) async {
    debugPrint('selectRestaurant called with $restaurantId, $tenantId');
    try {
      _currentRestaurantId = restaurantId;
      _currentTenantId = tenantId;

      debugPrint('Getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('Saving to SharedPreferences...');
      await prefs.setInt('selected_restaurant_id', restaurantId);
      await prefs.setInt('selected_tenant_id', tenantId);

      debugPrint('Loading restaurant data...');
      await loadRestaurantData();
      debugPrint('Restaurant data loaded. Notifying listeners...');
      notifyListeners();
    } catch (e) {
      _error = 'Error al seleccionar restaurante: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Cargar datos del restaurante actual
  Future<void> loadRestaurantData() async {
    debugPrint('loadRestaurantData called for $_currentRestaurantId');
    if (_currentRestaurantId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Fetching restaurant from API...');
      _currentRestaurant = await ApiService.fetchRestaurant(_currentRestaurantId!);
      debugPrint('Restaurant fetched: ${_currentRestaurant?.name}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar restaurante: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Cargar restaurantes disponibles para un tenant
  Future<void> loadAvailableRestaurants(int tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableRestaurants = await ApiService.fetchTenantRestaurants(tenantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar restaurantes: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Obtener headers para peticiones HTTP
  Map<String, String> getHeaders() {
    return {
      'X-Tenant-Id': _currentTenantId?.toString() ?? '1',
      'X-Restaurant-Id': _currentRestaurantId?.toString() ?? '1',
      'Accept': 'application/json',
    };
  }

  /// Limpiar selección
  Future<void> clearSelection() async {
    _currentRestaurantId = null;
    _currentTenantId = null;
    _currentRestaurant = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_restaurant_id');
    await prefs.remove('selected_tenant_id');

    notifyListeners();
  }

  /// Refrescar datos del restaurante actual
  Future<void> refresh() async {
    if (_currentRestaurantId != null) {
      await loadRestaurantData();
    }
  }

  Future<int> getRestaurantId() async {
      await initialize();
      return _currentRestaurantId ?? 1; // Default to 1 if null, or handle error
  }
}
