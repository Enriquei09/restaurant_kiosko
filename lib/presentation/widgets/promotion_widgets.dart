import 'package:flutter/material.dart';

/// Badge de promoción que se muestra sobre la tarjeta de un producto.
/// Ej: "-15%", "2x1", "COMBO"
class PromotionBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;

  const PromotionBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.red.shade600;
    final fgColor = textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Muestra precio original tachado + precio con descuento.
class PromotionPriceDisplay extends StatelessWidget {
  final double originalPrice;
  final double? discountedPrice;
  final String currencySymbol;
  final double originalFontSize;
  final double discountFontSize;

  const PromotionPriceDisplay({
    super.key,
    required this.originalPrice,
    this.discountedPrice,
    this.currencySymbol = '\$',
    this.originalFontSize = 12,
    this.discountFontSize = 14,
  });

  bool get hasDiscount =>
      discountedPrice != null && discountedPrice! < originalPrice;

  @override
  Widget build(BuildContext context) {
    if (!hasDiscount) {
      return Text(
        '$currencySymbol${originalPrice.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: discountFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Precio original tachado
        Text(
          '$currencySymbol${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: originalFontSize,
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.red.shade400,
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 4),
        // Precio con descuento
        Text(
          '$currencySymbol${discountedPrice!.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: discountFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}

/// Banner/chip para sugerencias de promoción en el carrito.
/// Ej: "🎉 ¡Agrega otro y la segunda es GRATIS!"
class PromotionSuggestionBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const PromotionSuggestionBanner({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade100, Colors.orange.shade100],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange.shade600),
          ],
        ),
      ),
    );
  }
}

/// Resumen de descuentos aplicados en el carrito.
class PromotionDiscountSummary extends StatelessWidget {
  final List<({String name, String badge, double discount})> promotions;
  final double totalDiscount;
  final String currencySymbol;

  const PromotionDiscountSummary({
    super.key,
    required this.promotions,
    required this.totalDiscount,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                'Promociones aplicadas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...promotions.map((p) => Padding(
                padding: const EdgeInsets.only(left: 22, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PromotionBadge(label: p.badge, fontSize: 8),
                        const SizedBox(width: 6),
                        Text(p.name, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    Text(
                      '-$currencySymbol${p.discount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total descuento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  fontSize: 12,
                ),
              ),
              Text(
                '-$currencySymbol${totalDiscount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
