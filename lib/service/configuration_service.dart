import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Servicio para manejar configuraciones dinámicas del restaurante
class ConfigurationService {
  static const String _restaurantIdKey = 'restaurant_id';
  static const String _restaurantNameKey = 'restaurant_name';
  static const String _configCacheKey = 'app_config_cache';
  static const String _configLastFetchKey = 'config_last_fetch';
  
  // Caché de configuraciones
  static Map<String, dynamic> _configCache = {};
  static const int _defaultRestaurantId = 1; // Fallback por defecto

  /// Obtener el ID del restaurante configurado
  static Future<int> getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    int? cachedId = prefs.getInt(_restaurantIdKey);
    
    if (cachedId != null) {
      return cachedId;
    }
    
    // Intentar obtener de la API
    try {
      await _fetchAndCacheConfig();
      return prefs.getInt(_restaurantIdKey) ?? _defaultRestaurantId;
    } catch (e) {
      // Usar valor por defecto si falla la API
      return _defaultRestaurantId;
    }
  }

  /// Obtener el nombre del restaurante
  static Future<String> getRestaurantName() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedName = prefs.getString(_restaurantNameKey);
    
    if (cachedName != null) {
      return cachedName;
    }
    
    try {
      await _fetchAndCacheConfig();
      return prefs.getString(_restaurantNameKey) ?? 'Mi Restaurante';
    } catch (e) {
      return 'Mi Restaurante';
    }
  }

  /// Obtener una configuración específica por clave
  static Future<String?> getConfig(String key) async {
    if (_configCache.isEmpty) {
      await _loadCachedConfig();
      
      // Si el caché está vacío o expirado, intentar refrescar
      if (_configCache.isEmpty || await _isCacheExpired()) {
        try {
          await _fetchAndCacheConfig();
        } catch (e) {
          // Continuar con caché existente o valores por defecto
        }
      }
    }
    
    return _configCache[key]?.toString();
  }

  /// Obtener configuración con valor por defecto
  static Future<T> getConfigWithDefault<T>(String key, T defaultValue) async {
    try {
      final value = await getConfig(key);
      if (value == null) return defaultValue;
      
      // Convertir al tipo esperado
      if (T == int) {
        return int.tryParse(value) as T? ?? defaultValue;
      } else if (T == double) {
        return double.tryParse(value) as T? ?? defaultValue;
      } else if (T == bool) {
        return (value.toLowerCase() == 'true') as T? ?? defaultValue;
      } else {
        return value as T? ?? defaultValue;
      }
    } catch (e) {
      return defaultValue;
    }
  }

  /// Establecer el ID del restaurante manualmente
  static Future<void> setRestaurantId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restaurantIdKey, id);
  }

  /// Refrescar configuraciones desde la API
  static Future<void> refreshConfig() async {
    await _fetchAndCacheConfig();
  }

  /// Limpiar caché de configuraciones
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configCacheKey);
    await prefs.remove(_configLastFetchKey);
    await prefs.remove(_restaurantIdKey);
    await prefs.remove(_restaurantNameKey);
    _configCache.clear();
  }

  /// Obtener configuraciones desde la API y guardarlas en caché
  static Future<void> _fetchAndCacheConfig() async {
    try {
      final url = Uri.parse('$baseUrl/config');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Guardar en caché local
        _configCache = data['configurations'] ?? {};
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_configCacheKey, jsonEncode(_configCache));
        await prefs.setInt(_configLastFetchKey, DateTime.now().millisecondsSinceEpoch);
        
        // Guardar configuraciones específicas importantes
        if (_configCache.containsKey('restaurant.id')) {
          final restaurantId = int.tryParse(_configCache['restaurant.id'].toString());
          if (restaurantId != null) {
            await prefs.setInt(_restaurantIdKey, restaurantId);
          }
        }
        
        if (_configCache.containsKey('restaurant.name')) {
          await prefs.setString(_restaurantNameKey, _configCache['restaurant.name'].toString());
        }
        
      } else {
        throw Exception('Error al obtener configuraciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al obtener configuraciones: $e');
    }
  }

  /// Cargar configuraciones del caché local
  static Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_configCacheKey);
      
      if (cachedData != null) {
        _configCache = Map<String, dynamic>.from(jsonDecode(cachedData));
      }
    } catch (e) {
      _configCache = {};
    }
  }

  /// Verificar si el caché ha expirado (24 horas)
  static Future<bool> _isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_configLastFetchKey);
      
      if (lastFetch == null) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - lastFetch;
      const twentyFourHours = 24 * 60 * 60 * 1000; // en milisegundos
      
      return diff > twentyFourHours;
    } catch (e) {
      return true;
    }
  }
}