import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import '../service/api_service.dart';

/// Provider de autenticación.
/// Gestiona login/logout, persistencia de sesión y verificación de permisos.
class AuthProvider with ChangeNotifier {
  AuthUser? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────

  AuthUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated => _user != null && _token != null;
  String get userName => _user?.name ?? '';
  String get roleName => _user?.role.name ?? '';

  // ── Permission getters (delegados al modelo) ──────────────

  bool get canTakeOrders => _user?.canTakeOrders ?? false;
  bool get canProcessPayments => _user?.canProcessPayments ?? false;
  bool get canOpenCashRegister => _user?.canOpenCashRegister ?? false;
  bool get canVoidOrders => _user?.canVoidOrders ?? false;
  bool get canApplyDiscounts => _user?.canApplyDiscounts ?? false;
  bool get canManageProducts => _user?.canManageProducts ?? false;
  bool get canViewReports => _user?.canViewReports ?? false;
  bool get canManageUsers => _user?.canManageUsers ?? false;

  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSupervisorOrAdmin => _user?.isSupervisorOrAdmin ?? false;

  // ── Role checks ───────────────────────────────────────────

  bool get isCashier => _user?.role.isCashier ?? false;
  bool get isWaiter => _user?.role.isWaiter ?? false;
  bool get isCook => _user?.role.isCook ?? false;
  bool get isBar => _user?.role.isBar ?? false;
  bool get isRunner => _user?.role.isRunner ?? false;

  /// Verificar un permiso específico por nombre.
  bool hasPermission(String permission) {
    return _user?.role.hasPermission(permission) ?? false;
  }

  /// Verificar si el usuario tiene alguno de los roles.
  bool hasRole(List<String> roles) {
    if (_user == null) return false;
    return roles.contains(_user!.role.name);
  }

  // ── Login ─────────────────────────────────────────────────

  /// Login con PIN del usuario.
  /// Llama a /api/auth/login-pin y guarda token + usuario en SharedPreferences.
  Future<bool> loginWithPin({
    required String pin,
    required int restaurantId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.loginByPin(
        pin: pin,
        restaurantId: restaurantId,
      );

      if (response['success'] == true) {
        _token = response['token'];
        _user = AuthUser.fromJson(response['user']);

        // Actualizar token global en ApiService
        ApiService.setAuthToken(_token!);

        // Persistir sesión
        await _saveSession();

        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Error de autenticación';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────

  /// Cerrar sesión, revocar token y limpiar persistencia.
  Future<void> logout() async {
    try {
      if (_token != null) {
        await ApiService.logout();
      }
    } catch (_) {
      // Ignorar errores de red en logout
    }

    _user = null;
    _token = null;
    _error = null;
    ApiService.setAuthToken('');

    await _clearSession();
    notifyListeners();
  }

  // ── Restaurar sesión ──────────────────────────────────────

  /// Intentar restaurar sesión guardada en SharedPreferences.
  /// Retorna true si había sesión válida.
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('auth_user');
      final savedToken = prefs.getString('auth_token');

      if (userJson != null && savedToken != null) {
        _user = AuthUser.fromJson(jsonDecode(userJson));
        _token = savedToken;
        ApiService.setAuthToken(_token!);

        // Validar que el token siga siendo válido
        try {
          final meResponse = await ApiService.getMe();
          if (meResponse['success'] == true) {
            _user = AuthUser.fromJson(meResponse['user']);
            await _saveSession(); // Actualizar datos locales
            notifyListeners();
            return true;
          }
        } catch (_) {
          // Token expirado o inválido
        }

        // Si llegamos aquí, el token ya no es válido
        await _clearSession();
        _user = null;
        _token = null;
        ApiService.setAuthToken('');
        notifyListeners();
        return false;
      }
    } catch (_) {
      // Error al leer SharedPreferences
    }

    return false;
  }

  // ── Persistencia interna ──────────────────────────────────

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
    }
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
    await prefs.remove('auth_token');
  }
}
