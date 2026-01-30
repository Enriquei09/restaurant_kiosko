class RestaurantTable {
  final int id;
  final String name;
  final String? section;
  final int capacity;
  final String status; // 'available', 'occupied', 'reserved', 'dirty'

  RestaurantTable({
    required this.id,
    required this.name,
    this.section,
    required this.capacity,
    required this.status,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'],
      name: json['name'],
      section: json['section'],
      capacity: json['capacity'] ?? 4,
      status: json['status'] ?? 'available',
    );
  }
}
