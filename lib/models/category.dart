import '../models/product_group.dart';
class Category {
  final int id;
  final String name;
  final String imagePath;
  final List<ProductGroup>productGroups;

  Category({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.productGroups,
  });

factory Category.fromJson(Map<String, dynamic> json) {
  return Category(
    id: json['id'],
    name: json['name'],
    imagePath: json['image_path'],
    productGroups: (json['product_groups'] ?? [])
        .map<ProductGroup>((g) => ProductGroup.fromJson(g))
        .toList(),
  );
}
}
