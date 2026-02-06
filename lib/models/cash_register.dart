class CashRegister {
  final int id;
  final int tenantId;
  final int restaurantId;
  final int? locationId;
  final int userId;
  final int? terminalId;
  final double openingBalance;
  final double? closingBalance;
  final double? expectedBalance;
  final double? difference;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String status; // 'open' | 'closed'
  final String? openingNotes;
  final String? closingNotes;
  final Map<String, dynamic>? denominationDetails;
  final User? user;
  final Restaurant? restaurant;
  final Terminal? terminal;

  CashRegister({
    required this.id,
    required this.tenantId,
    required this.restaurantId,
    this.locationId,
    required this.userId,
    this.terminalId,
    required this.openingBalance,
    this.closingBalance,
    this.expectedBalance,
    this.difference,
    required this.openedAt,
    this.closedAt,
    required this.status,
    this.openingNotes,
    this.closingNotes,
    this.denominationDetails,
    this.user,
    this.restaurant,
    this.terminal,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json['id'],
      tenantId: json['tenant_id'],
      restaurantId: json['restaurant_id'],
      locationId: json['location_id'],
      userId: json['user_id'],
      terminalId: json['terminal_id'],
      openingBalance: double.parse(json['opening_balance'].toString()),
      closingBalance: json['closing_balance'] != null
          ? double.parse(json['closing_balance'].toString())
          : null,
      expectedBalance: json['expected_balance'] != null
          ? double.parse(json['expected_balance'].toString())
          : null,
      difference: json['difference'] != null
          ? double.parse(json['difference'].toString())
          : null,
      openedAt: DateTime.parse(json['opened_at']),
      closedAt:
          json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      status: json['status'],
      openingNotes: json['opening_notes'],
      closingNotes: json['closing_notes'],
      denominationDetails: json['denomination_details'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'])
          : null,
      terminal: json['terminal'] != null
          ? Terminal.fromJson(json['terminal'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'restaurant_id': restaurantId,
      'location_id': locationId,
      'user_id': userId,
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'expected_balance': expectedBalance,
      'difference': difference,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'status': status,
      'opening_notes': openingNotes,
      'closing_notes': closingNotes,
      'denomination_details': denominationDetails,
    };
  }

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
}

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class Restaurant {
  final int id;
  final String name;

  Restaurant({required this.id, required this.name});

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Terminal {
  final int id;
  final String terminalNumber;
  final String name;
  final String? location;

  Terminal({
    required this.id,
    required this.terminalNumber,
    required this.name,
    this.location,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'],
      terminalNumber: json['terminal_number'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
    );
  }
}

class SalesSummary {
  final int totalOrders;
  final double totalSales;
  final double cashSales;
  final double cardSales;
  final double totalTips;

  SalesSummary({
    required this.totalOrders,
    required this.totalSales,
    required this.cashSales,
    required this.cardSales,
    required this.totalTips,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      totalOrders: json['total_orders'] ?? 0,
      totalSales: double.parse((json['total_sales'] ?? 0).toString()),
      cashSales: double.parse((json['cash_sales'] ?? 0).toString()),
      cardSales: double.parse((json['card_sales'] ?? 0).toString()),
      totalTips: double.parse((json['total_tips'] ?? 0).toString()),
    );
  }
}
