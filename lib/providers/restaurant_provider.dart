import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../models/restaurant_config.dart';
import '../models/screensaver_config.dart';
import '../service/api_service.dart';

class RestaurantProvider extends ChangeNotifier {
  int? _currentRestaurantId;
  int? _currentTenantId;
  Restaurant? _currentRestaurant;
  RestaurantConfig _config = RestaurantConfig.defaults();
  ScreensaverConfig _screensaverConfig = const ScreensaverConfig();
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

  /// Configuración del restaurante (colores, moneda, impuestos, etc.)
  RestaurantConfig get config => _config;

  /// Configuración del screensaver.
  ScreensaverConfig get screensaverConfig => _screensaverConfig;
  bool get screensaverEnabled => _screensaverConfig.isActive;
  Duration get screensaverTimeout =>
      Duration(seconds: _screensaverConfig.timeoutSeconds);

  /// ThemeData generado desde los colores del restaurante.
  ThemeData get themeData => _config.toThemeData();

  /// Color primario del restaurante.
  Color get primaryColor => _config.primaryColor;

  /// Inicializar desde SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentRestaurantId = prefs.getInt('selected_restaurant_id');
      _currentTenantId = prefs.getInt('selected_tenant_id');

      // Sincronizar con ApiService para que todas las requests usen X-Restaurant-Id
      if (_currentRestaurantId != null) {
        ApiService.setRestaurantId(_currentRestaurantId!);
      }

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
      
      // Sincronizar con ApiService para que todas las requests usen X-Restaurant-Id
      ApiService.setRestaurantId(restaurantId);

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

      // Cargar configuración (colores, impuestos, features, etc.)
      try {
        final settingsJson = await ApiService.fetchRestaurantSettings(_currentRestaurantId!);
        _config = RestaurantConfig.fromJson(settingsJson);
        debugPrint('Restaurant config loaded: ${_config.displayName}');
      } catch (e) {
        debugPrint('Could not load restaurant settings, using defaults: $e');
        _config = RestaurantConfig.defaults();
      }

      // Cargar configuración del screensaver
      try {
        _screensaverConfig = await ApiService.fetchScreensaver(_currentRestaurantId!);
        debugPrint('Screensaver loaded: ${_screensaverConfig.images.length} images, enabled: ${_screensaverConfig.enabled}');
      } catch (e) {
        debugPrint('Could not load screensaver config: $e');
        _screensaverConfig = const ScreensaverConfig();
      }

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
