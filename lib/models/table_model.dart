class RestaurantTable {
  final int id;
  final String name;
  final String? section;
  final int capacity;
  final String status; // 'available' | 'occupied' | 'bill_printed'

  // ── Campos de la nueva API de estados ──────────────────────
  final int? lockedByUserId;      // null = sin lock
  final int? currentOrderId;      // orden activa
  final bool isLockedByOther;     // otro mesero tiene el lock
  final bool isLockedByMe;        // yo tengo el lock
  final bool isBillPrinted;       // cuenta congelada
  final bool isAvailable;
  final bool isOccupied;
  final String uiColor;           // hex del servidor (#E91E63, #0056D2, etc.)

  const RestaurantTable({
    required this.id,
    required this.name,
    this.section,
    required this.capacity,
    required this.status,
    this.lockedByUserId,
    this.currentOrderId,
    this.isLockedByOther = false,
    this.isLockedByMe    = false,
    this.isBillPrinted   = false,
    this.isAvailable     = false,
    this.isOccupied      = false,
    this.uiColor         = '#E0E0E0',
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'available';
    return RestaurantTable(
      id:               json['id'] ?? 0,
      name:             json['name']?.toString() ?? '',
      section:          json['section']?.toString(),
      capacity:         json['capacity'] ?? 4,
      status:           status,
      lockedByUserId:   json['locked_by_user_id'] as int?,
      currentOrderId:   json['current_order_id'] as int?,
      isLockedByOther:  json['is_locked_by_other'] == true,
      isLockedByMe:     json['is_locked_by_me'] == true,
      isBillPrinted:    json['is_bill_printed'] == true,
      isAvailable:      json['is_available'] == true,
      isOccupied:       json['is_occupied'] == true,
      uiColor:          json['ui_color']?.toString() ?? '#E0E0E0',
    );
  }

  /// Crea una copia con campos modificados (para actualizaciones optimistas).
  RestaurantTable copyWith({
    String? status,
    int? lockedByUserId,
    int? currentOrderId,
    bool? isLockedByOther,
    bool? isLockedByMe,
    bool? isBillPrinted,
    bool? isAvailable,
    bool? isOccupied,
    String? uiColor,
    bool clearLock = false,
    bool clearOrder = false,
  }) {
    return RestaurantTable(
      id:              id,
      name:            name,
      section:         section,
      capacity:        capacity,
      status:          status       ?? this.status,
      lockedByUserId:  clearLock    ? null : (lockedByUserId  ?? this.lockedByUserId),
      currentOrderId:  clearOrder   ? null : (currentOrderId  ?? this.currentOrderId),
      isLockedByOther: isLockedByOther ?? this.isLockedByOther,
      isLockedByMe:    isLockedByMe    ?? this.isLockedByMe,
      isBillPrinted:   isBillPrinted   ?? this.isBillPrinted,
      isAvailable:     isAvailable     ?? this.isAvailable,
      isOccupied:      isOccupied      ?? this.isOccupied,
      uiColor:         uiColor         ?? this.uiColor,
    );
  }
}
