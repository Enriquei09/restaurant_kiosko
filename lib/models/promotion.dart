/// Modelo de una promoción activa recibida del API.
class Promotion {
  final int id;
  final String name;
  final String? description;
  final String type; // percentage, 2x1, fixed_amount, combo
  final double value;
  final bool isCombo;
  final String badgeLabel;
  final bool showBadge;
  final String? imageUrl;
  final String? thumbnailUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minPurchase;
  final double? maxDiscount;
  final List<int> productIds;
  final List<RequiredProduct> requiredProducts;

  const Promotion({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.value,
    this.isCombo = false,
    required this.badgeLabel,
    this.showBadge = true,
    this.imageUrl,
    this.thumbnailUrl,
    this.startDate,
    this.endDate,
    this.minPurchase,
    this.maxDiscount,
    this.productIds = const [],
    this.requiredProducts = const [],
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      isCombo: json['is_combo'] ?? false,
      badgeLabel: json['badge_label'] ?? 'PROMO',
      showBadge: json['show_badge'] ?? true,
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      minPurchase: (json['min_purchase'] as num?)?.toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      productIds: List<int>.from(json['products'] ?? []),
      requiredProducts: (json['required_products'] as List?)
              ?.map((e) => RequiredProduct.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// ¿Aplica a este producto específico?
  bool appliesTo(int productId) {
    if (productIds.isEmpty) return true; // global
    return productIds.contains(productId);
  }
}

class RequiredProduct {
  final int id;
  final String name;
  final int quantity;

  const RequiredProduct({
    required this.id,
    required this.name,
    this.quantity = 1,
  });

  factory RequiredProduct.fromJson(Map<String, dynamic> json) {
    return RequiredProduct(
      id: json['id'],
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}

/// Resultado de la validación del carrito contra promociones.
class CartPromotionResult {
  final List<ApplicablePromotion> applicable;
  final List<PromotionSuggestion> suggestions;
  final double subtotal;
  final double totalDiscount;
  final double total;

  const CartPromotionResult({
    this.applicable = const [],
    this.suggestions = const [],
    this.subtotal = 0,
    this.totalDiscount = 0,
    this.total = 0,
  });

  factory CartPromotionResult.fromJson(Map<String, dynamic> json) {
    return CartPromotionResult(
      applicable: (json['applicable'] as List?)
              ?.map((e) => ApplicablePromotion.fromJson(e))
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List?)
              ?.map((e) => PromotionSuggestion.fromJson(e))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get hasDiscounts => totalDiscount > 0;
  bool get hasSuggestions => suggestions.isNotEmpty;
}

class ApplicablePromotion {
  final int promotionId;
  final String name;
  final String type;
  final String badgeLabel;
  final double discount;
  final List<int> affectedProducts;
  final String? description;

  const ApplicablePromotion({
    required this.promotionId,
    required this.name,
    required this.type,
    required this.badgeLabel,
    required this.discount,
    this.affectedProducts = const [],
    this.description,
  });

  factory ApplicablePromotion.fromJson(Map<String, dynamic> json) {
    return ApplicablePromotion(
      promotionId: json['promotion_id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      badgeLabel: json['badge_label'] ?? '',
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      affectedProducts: List<int>.from(json['affected_products'] ?? []),
      description: json['description'],
    );
  }
}

class PromotionSuggestion {
  final String type; // '2x1' o 'combo'
  final int promotionId;
  final String message;
  final int? productId;
  final List<Map<String, dynamic>>? missingProducts;
  final String badge;

  const PromotionSuggestion({
    required this.type,
    required this.promotionId,
    required this.message,
    this.productId,
    this.missingProducts,
    required this.badge,
  });

  factory PromotionSuggestion.fromJson(Map<String, dynamic> json) {
    return PromotionSuggestion(
      type: json['type'] ?? '',
      promotionId: json['promotion_id'],
      message: json['message'] ?? '',
      productId: json['product_id'],
      missingProducts: (json['missing_products'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      badge: json['badge'] ?? '',
    );
  }
}
