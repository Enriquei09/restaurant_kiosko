class CashRegisterTerminal {
  final int id;
  final int? restaurantId;
  final String terminalNumber;
  final String name;
  final String? location;
  final bool isActive;
  final Map<String, dynamic>? currentCashRegister;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hasOpenRegister;
  final String status;

  CashRegisterTerminal({
    required this.id,
    this.restaurantId,
    required this.terminalNumber,
    required this.name,
    this.location,
    this.isActive = true,
    this.currentCashRegister,
    this.createdAt,
    this.updatedAt,
    this.hasOpenRegister = false,
    this.status = 'available',
  });

  factory CashRegisterTerminal.fromJson(Map<String, dynamic> json) {
    return CashRegisterTerminal(
      id: json['id'] ?? 0,
      restaurantId: json['restaurant_id'],
      terminalNumber: json['terminal_number'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      currentCashRegister: json['current_cash_register'],
      hasOpenRegister: json['has_open_register'] ?? false,
      status: json['status'] ?? 'available',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'terminal_number': terminalNumber,
      'name': name,
      'location': location,
      'is_active': isActive,
      'current_cash_register': currentCashRegister,
      'has_open_register': hasOpenRegister,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isAvailable => isActive && !hasOpenRegister;
}