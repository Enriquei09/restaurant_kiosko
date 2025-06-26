class Product {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final int? productGroupId; // 👈 puede ser null
  final String description;
  final String color;
  final String imagePath;
  final bool active;
  final bool outOfStock;
  final bool imageSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.productGroupId, // 👈 null-safe
    required this.description,
    required this.color,
    required this.imagePath,
    required this.active,
    required this.outOfStock,
    required this.imageSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name']?.toString() ?? 'Producto sin nombre',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      categoryId: json['category_id'],
      productGroupId: json['product_group_id'],
      description: json['description']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? 'assets/img_comida/comida_mexicana.jpg',
      active: json['active'] ?? true,
      outOfStock: json['out_of_stock'] ?? false,
      imageSynced: json['image_synced'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'product_group_id': productGroupId,
      'description': description,
      'color': color,
      'image_path': imagePath,
      'active': active,
      'out_of_stock': outOfStock,
      'image_synced': imageSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
