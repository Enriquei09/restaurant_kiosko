class CartItem {
  final int productId;
  final String name;
  final String? description;
  final double unitPrice;
  final int qty;
  final List<int> modifierIds; // extras seleccionados
  final String? note;
  final String? imagePath;     // opcional para mostrar imagen
  final List<String> modifierLabels;

  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    this.description,
    this.qty = 1,
    this.modifierIds = const [],
    this.note,
    this.imagePath,
     this.modifierLabels = const [],
  });

  CartItem copyWith({int? qty}) => CartItem(
    productId: productId,
    name: name,
    description: description,
    unitPrice: unitPrice,
    qty: qty ?? this.qty,
    modifierIds: modifierIds,
    note: note,
    imagePath: imagePath,
    modifierLabels: modifierLabels, 
  );

  /// Clave única que identifica la combinación exacta de producto + opciones + nota.
  /// Misma combinación  → autoincremento de cantidad.
  /// Distinta combinación → línea nueva e independiente en el carrito.
  String get uniqueCombinationKey {
    final sortedIds = List<int>.from(modifierIds)..sort();
    final mods = sortedIds.join('-');
    final noteKey = (note ?? '').trim();
    return '${productId}_${mods}_$noteKey';
  }

  double get modifierTotal => 0; // si cobras extras, súmalos aquí
  double get line => (unitPrice + modifierTotal) * qty;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'description':description,
    'unit_price': unitPrice,
    'qty': qty,
    'modifiers': modifierIds,
    'note': note,
    'image_path': imagePath,
    'modifier_labels': modifierLabels,  
  };

  factory CartItem.fromJson(Map<String, dynamic> m) => CartItem(
    productId: m['product_id'],
    name: m['name'],
     description: m['description'], 
    unitPrice: (m['unit_price'] as num).toDouble(),
    qty: m['qty'],
    modifierIds: List<int>.from(m['modifiers'] ?? []),
    note: m['note'],
    imagePath: m['image_path'],
    modifierLabels: (m['modifier_labels'] as List?)?.map((e)=>e.toString()).toList() ?? const [],

  );
}
