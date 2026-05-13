import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/presentation/widgets/edit_cart_item_dialog.dart';
import 'package:restaurant_kiosco/presentation/widgets/promotion_widgets.dart';

const Color _mexicanPink = Color(0xFFE4007C);

class ProductsSelected extends StatelessWidget {
  const ProductsSelected({super.key});

  /// Helper para abrir el modal permitiendo cerrar tocando afuera.
  static Future<bool?> show(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true, // tap fuera del modal = cerrar
      barrierLabel: 'Cerrar carrito',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(dialogContext),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.42)),
              ),
            ),
            const SafeArea(
              child: Align(
                alignment: Alignment.centerRight,
                child: ProductsSelected(),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final size = MediaQuery.of(context).size;
    final panelWidth = size.width >= 1000 ? size.width * 0.40 : size.width * 0.92;
    final panelHeight = size.height - 24;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: panelWidth,
        height: panelHeight,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Productos Seleccionados',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Lista del carrito
                Expanded(
                  child: cart.items.isEmpty
                      ? const Center(child: Text('Tu carrito está vacío'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _CartRow(index: i),
                        ),
                ),

                // Sugerencias de promoción
                if (cart.promotionSuggestions.isNotEmpty)
                  ...cart.promotionSuggestions.map((s) => PromotionSuggestionBanner(
                        message: s.message,
                      )),

                const Divider(height: 1),

                // Totales + acciones
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    children: [
                      // Descuentos aplicados
                      if (cart.appliedPromotions.isNotEmpty)
                        PromotionDiscountSummary(
                          promotions: cart.appliedPromotions
                              .map((p) => (
                                    name: p.name,
                                    badge: p.badgeLabel,
                                    discount: p.discount,
                                  ))
                              .toList(),
                          totalDiscount: cart.promotionDiscount,
                        ),
                      _total('Subtotal', cart.subtotal),
                      if (cart.promotionDiscount > 0)
                        _total('Descuento', -cart.promotionDiscount, isDiscount: true),
                      _total('IVA (16%)', cart.tax),
                      if (cart.loadingPromotions)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: LinearProgressIndicator(),
                        ),
                      _total('Total', cart.total, bold: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/checkout');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mexicanPink,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _total(String label, double value, {bool bold = false, bool isDiscount = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : isDiscount
            ? TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)
            : null;
    final prefix = isDiscount ? '-' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('$prefix\$${value.abs().toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Item del carrito: tap o botón "Editar" → abre el selector
// ──────────────────────────────────────────────────────────────────────────────
class _CartRow extends StatefulWidget {
  final int index;
  const _CartRow({required this.index});

  @override
  State<_CartRow> createState() => _CartRowState();
}

class _CartRowState extends State<_CartRow> {
  late TextEditingController _controller;
  bool isEditingQty = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartModel>();
    _controller = TextEditingController(text: cart.items[widget.index].qty.toString());
  }

  @override
  void didUpdateWidget(covariant _CartRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cart = context.read<CartModel>();
    if (widget.index < cart.items.length) {
      _controller.text = cart.items[widget.index].qty.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final it = cart.items[widget.index];

    Widget image() {
      final path = it.imagePath;
      if (path == null || path.isEmpty) {
        return Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fastfood),
        );
      }
      final isNetwork = path.startsWith('http');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isNetwork
            ? Image.network(path, width: 50, height: 50, fit: BoxFit.cover)
            : Image.asset(path, width: 50, height: 50, fit: BoxFit.cover),
      );
    }

    // 👉 Toda la tarjeta es "clickeable" para abrir el editor
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => EditCartItemDialog.show(context, index: widget.index),
      child: Card(
        elevation: 0,
        color: const Color(0xFFFCFCFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                children: [
                  image(),
                  const SizedBox(width: 10),

                  // Nombre + precio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${it.unitPrice.toStringAsFixed(2)} c/u'),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      _QtyCircleButton(
                        icon: Icons.remove,
                        onTap: () => cart.decrease(widget.index),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${it.qty}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      _QtyCircleButton(
                        icon: Icons.add,
                        onTap: () => cart.setQty(widget.index, it.qty + 1),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => cart.removeAt(widget.index),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),

              // Modificadores (labels)
              if (it.modifierLabels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: it.modifierLabels
                        .map((lbl) => Chip(
                              label: Text(lbl),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ),
              ],

              // Nota
              if (it.note != null && it.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(it.note!, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: _mexicanPink,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}

class OrderCartSummary extends ProductsSelected {
  const OrderCartSummary({super.key});
}
