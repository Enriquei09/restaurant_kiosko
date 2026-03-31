import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_user.dart';
import '../service/api_service.dart';

/// Provider de autenticación.
/// Gestiona login/logout, persistencia segura (FlutterSecureStorage)
/// y verificación de permisos.
class AuthProvider with ChangeNotifier {
  // ── Almacenamiento seguro ──────────────────────────────────────────────────
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _kToken = 'auth_token';
  static const _kRole  = 'auth_role';
  static const _kUser  = 'auth_user';

  // ── Estado interno ─────────────────────────────────────────────────────────
  AuthUser? _user;
  String?   _token;
  bool      _isLoading     = false;
  bool      _isInitialized = false;
  String?   _error;

  // ── Getters ────────────────────────────────────────────────

  AuthUser? get user          => _user;
  String?   get token         => _token;
  bool      get isLoading     => _isLoading;
  bool      get isInitialized => _isInitialized;
  String?   get error         => _error;

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
  ///
  /// Guarda el [token] y el [roleName] en [FlutterSecureStorage]
  /// y llama [notifyListeners] al finalizar para que main.dart
  /// redirija según el rol con un switch.
  ///
  /// Retorna `true` si el login fue exitoso.
  Future<bool> login(String pin, int restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.loginByPin(
        pin: pin,
        restaurantId: restaurantId,
      );

      if (response['success'] == true) {
        _token = response['token'] as String;
        _user  = AuthUser.fromJson(response['user'] as Map<String, dynamic>);

        // Actualizar token global en ApiService
        ApiService.setAuthToken(_token!);

        // Persistir token y role en SecureStorage
        await _saveSession();

        _isLoading = false;
        _error     = null;
        notifyListeners(); // main.dart escucha → redirige según el rol
        return true;
      }

      _error     = (response['message'] as String?) ?? 'Error de autenticación';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error     = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Alias con parámetros nombrados para compatibilidad con código existente.
  Future<bool> loginWithPin({required String pin, required int restaurantId}) =>
      login(pin, restaurantId);

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

  /// Intenta restaurar la sesión guardada en [FlutterSecureStorage].
  ///
  /// Establece [isInitialized] = `true` al terminar (con o sin sesión).
  /// Retorna `true` si había sesión válida.
  Future<bool> restoreSession() async {
    try {
      final savedToken = await _storage.read(key: _kToken);
      final userJson   = await _storage.read(key: _kUser);

      if (savedToken != null && userJson != null) {
        _user  = AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _token = savedToken;
        ApiService.setAuthToken(_token!);

        // Validar que el token siga siendo válido en el servidor
        try {
          final meResponse = await ApiService.getMe();
          if (meResponse['success'] == true) {
            _user = AuthUser.fromJson(
                meResponse['user'] as Map<String, dynamic>);
            await _saveSession(); // Actualizar datos locales
            _isInitialized = true;
            notifyListeners();
            return true;
          }
        } catch (_) {
          // Token expirado o sin conexión
        }

        // Token inválido — limpiar
        await _clearSession();
        _user  = null;
        _token = null;
        ApiService.setAuthToken('');
      }
    } catch (_) {
      // Error de lectura
    }

    _isInitialized = true;
    notifyListeners();
    return false;
  }

  // ── Persistencia interna ──────────────────────────────────────────────────

  /// Guarda token, role (nombre) y datos completos del usuario en SecureStorage.
  Future<void> _saveSession() async {
    final futures = <Future>[];
    if (_token != null) {
      futures.add(_storage.write(key: _kToken, value: _token!));
    }
    if (_user != null) {
      futures.add(
        _storage.write(key: _kUser, value: jsonEncode(_user!.toJson())),
      );
      // Guarda el nombre del rol explícitamente para lecturas rápidas
      futures.add(_storage.write(key: _kRole, value: _user!.role.name));
    }
    await Future.wait(futures);
  }

  /// Elimina token, role y usuario de SecureStorage.
  Future<void> _clearSession() async {
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kRole),
      _storage.delete(key: _kUser),
    ]);
  }
}
