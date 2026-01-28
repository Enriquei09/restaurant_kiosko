class KitchenOrder {
  final int id;
  final String status;
  final String? clientName;
  final String? clientPhone;
  final double total;
  final double tip;
  final String createdAt;
  final List<KitchenOrderItem> items;

  KitchenOrder({
    required this.id,
    required this.status,
    this.clientName,
    this.clientPhone,
    required this.total,
    required this.tip,
    required this.createdAt,
    required this.items,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      id: json['id'],
      status: json['status'],
      clientName: json['client']?['name'],
      clientPhone: json['client']?['phone'],
      total: double.parse(json['total'].toString()),
      tip: double.parse(json['tip'].toString()),
      createdAt: json['created_at'],
      items: (json['order_details'] as List)
          .map((item) => KitchenOrderItem.fromJson(item))
          .toList(),
    );
  }

  // Helper para obtener color según status
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'preparing':
        return 'En Preparación';
      case 'ready':
        return 'Listo';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
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
      productName: json['product']['name'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unit_price'].toString()),
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
