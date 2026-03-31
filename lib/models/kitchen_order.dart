class KitchenOrder {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String? clientName;
  final String? clientPhone;
  final double total;
  final double tip;
  final DateTime createdAt;
  final List<KitchenOrderItem> items;
  final String? tableName;
  final String? tableNumber;

  KitchenOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    this.clientName,
    this.clientPhone,
    required this.total,
    required this.tip,
    required this.createdAt,
    required this.items,
    this.tableName,
    this.tableNumber,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      id: json['id'],
      orderNumber: json['order_number']?.toString() ?? json['id'].toString(),
      status: json['status'],
      paymentStatus: json['payment_status'] ?? 'pending',
      clientName: json['client']?['name'],
      clientPhone: json['client']?['phone'],
      tableName: json['table']?['name'],
      tableNumber: json['table']?['table_number']?.toString(),
      total: double.parse(json['total'].toString()),
      tip: double.parse(json['tip'].toString()),
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      items: ((json['order_details'] as List?) ?? [])
          .map((item) => KitchenOrderItem.fromJson(item))
          .toList(),
    );
  }

  // Helper para obtener color según status (Legacy)
  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pendiente Pago';
      case 'confirmed': return 'Por Preparar';
      case 'preparing': return 'En Preparación';
      case 'ready': return 'Listo';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }

  // Helper para determinar minutos transcurridos
  int get elapsedMinutes {
    return DateTime.now().difference(createdAt).inMinutes;
  }

  // Helper para determinar "Comer Aquí" vs "Para Llevar"
  String get orderTypeLabel {
    // 1. Priority: Assigned Table (Waiter / Dine In with Number)
    if (tableName != null) {
      if (clientName != null) return 'Mesa $tableName ($clientName)';
      return 'Mesa $tableName';
    }

    // 2. Kiosk Tags
    if (items.isNotEmpty && items[0].notes != null) {
      if (items[0].notes!.contains('PARA COMER AQUÍ')) return 'Comer Aquí';
      if (items[0].notes!.contains('PARA LLEVAR')) return 'Llevar';
    }
    
    // 3. Fallback
    return 'Llevar'; // Default to Take Away
  }

  bool get isTakeAway => orderTypeLabel == 'Llevar';
}

class KitchenOrderItem {
  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? notes;
  final List<String> modifiers;

  KitchenOrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    required this.modifiers,
  });

  factory KitchenOrderItem.fromJson(Map<String, dynamic> json) {
    final modifiersList = (json['modifiers'] as List?)
            ?.map((m) => m['name'].toString())
            .toList() ??
        [];

    return KitchenOrderItem(
      id: json['id'],
      productName: json['product']?['name']?.toString() ?? 'Producto desconocido',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
      modifiers: modifiersList,
    );
  }
}

class KitchenResponse {
  final List<KitchenOrder> orders;
  final Map<String, int> counts;
  final String serverTime;

  KitchenResponse({
    required this.orders,
    required this.counts,
    required this.serverTime,
  });

  factory KitchenResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return KitchenResponse(
      orders: (data['orders'] as List)
          .map((o) => KitchenOrder.fromJson(o))
          .toList(),
      counts: Map<String, int>.from(data['counts']),
      serverTime: data['server_time'],
    );
  }
}
