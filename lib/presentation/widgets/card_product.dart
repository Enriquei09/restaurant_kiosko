import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product.dart';
import 'package:restaurant_kiosco/presentation/widgets/produc_description.dart';

const Color _mexicanPink = Color(0xFFE4007C);
const Color _darkBluePrice = Color(0xFF1E3A6D);

class CardProduct extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const CardProduct({
    super.key,
    required this.product,
    this.onTap,
  });

  void _openProduct(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black38,
      builder: (_) => ProductDescription(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _openProduct(context),
      child: _ProductMiniCard(
        imagePath: product.imagePath,
        title: product.name,
        price: product.price,
        onQuickAdd: onTap ?? () => _openProduct(context),
      ),
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final double price;
  final VoidCallback onQuickAdd;

  const _ProductMiniCard({
    required this.imagePath,
    required this.title,
    required this.price,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imagePath.startsWith('http');

    return SizedBox(
      height: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 60% superior: imagen ──────────────────────────────
              SizedBox(
                height: 260 * 0.60,
                child: isNetwork
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      ),
              ),

              // ── 40% inferior: nombre, precio y botón ─────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nombre
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),

                      // Precio + botón Añadir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: _darkBluePrice,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: FloatingActionButton(
                              heroTag: null,
                              mini: true,
                              elevation: 0,
                              backgroundColor: _mexicanPink,
                              onPressed: onQuickAdd,
                              child: const Icon(
                                Icons.add,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.restaurant_menu, size: 48, color: Color(0xFFCCCCCC)),
        ),
      );
}
