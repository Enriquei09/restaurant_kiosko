/// Modelo de rol del usuario con permisos granulares.
class UserRole {
  final int id;
  final String name;
  final String? description;
  final Map<String, bool> permissions;

  const UserRole({
    required this.id,
    required this.name,
    this.description,
    required this.permissions,
  });

  // ── Permission getters ───────────────────────────────────

  bool get canTakeOrders => permissions['can_take_orders'] ?? false;
  bool get canProcessPayments => permissions['can_process_payments'] ?? false;
  bool get canOpenCashRegister => permissions['can_open_cash_register'] ?? false;
  bool get canVoidOrders => permissions['can_void_orders'] ?? false;
  bool get canApplyDiscounts => permissions['can_apply_discounts'] ?? false;
  bool get canManageProducts => permissions['can_manage_products'] ?? false;
  bool get canViewReports => permissions['can_view_reports'] ?? false;
  bool get canManageUsers => permissions['can_manage_users'] ?? false;

  // ── Role checks ──────────────────────────────────────────

  bool get isAdmin => name == 'admin';
  bool get isSupervisor => name == 'supervisor';
  bool get isCashier => name == 'cashier';
  bool get isWaiter => name == 'waiter';
  bool get isCook => name == 'cook';
  bool get isBar => name == 'bar';
  bool get isRunner => name == 'runner';

  bool get isSupervisorOrAdmin => isAdmin || isSupervisor;

  /// Verificar si tiene un permiso específico.
  bool hasPermission(String permission) {
    if (isAdmin) return true; // Admin siempre tiene acceso total
    return permissions[permission] ?? false;
  }

  // ── Serialization ────────────────────────────────────────

  factory UserRole.fromJson(Map<String, dynamic> json) {
    final permissionsData = json['permissions'] as Map<String, dynamic>? ?? {};
    final Map<String, bool> permissions = {};
    permissionsData.forEach((key, value) {
      permissions[key] = value == true || value == 1;
    });

    return UserRole(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
    };
  }

  @override
  String toString() => 'UserRole($name)';
}

/// Modelo de usuario autenticado.
class AuthUser {
  final int id;
  final String name;
  final String email;
  final int restaurantId;
  final UserRole role;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.restaurantId,
    required this.role,
  });

  // ── Delegated permission checks ──────────────────────────

  bool get canTakeOrders => role.canTakeOrders;
  bool get canProcessPayments => role.canProcessPayments;
  bool get canOpenCashRegister => role.canOpenCashRegister;
  bool get canVoidOrders => role.canVoidOrders;
  bool get canApplyDiscounts => role.canApplyDiscounts;
  bool get canManageProducts => role.canManageProducts;
  bool get canViewReports => role.canViewReports;
  bool get canManageUsers => role.canManageUsers;

  bool get isAdmin => role.isAdmin;
  bool get isSupervisorOrAdmin => role.isSupervisorOrAdmin;

  String get roleName => role.name;

  // ── Serialization ────────────────────────────────────────

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      restaurantId: json['restaurant_id'] ?? 0,
      role: UserRole.fromJson(json['role'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'restaurant_id': restaurantId,
      'role': role.toJson(),
    };
  }

  @override
  String toString() => 'AuthUser($name, role: ${role.name})';
}
