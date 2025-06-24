import 'product.dart';

class ProductGroup {
  final int id;
  final String name;
  final List<Product> products;

  ProductGroup({
    required this.id,
    required this.name,
    required this.products,
  });

factory ProductGroup.fromJson(Map<String, dynamic> json) {
  return ProductGroup(
    id: json['id'],
    name: json['name'],
    products: (json['products'] ?? [])
        .map<Product>((p) => Product.fromJson(p))
        .toList(),
  );
}
}
