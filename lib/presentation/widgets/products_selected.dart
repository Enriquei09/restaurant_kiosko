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

    // 👉 Toda la tarjeta es "clickeable" para abrir el editor
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => EditCartItemDialog.show(context, index: widget.index),
      child: Card(
        elevation: 0,
        color: const Color(0xFFFCFCFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Nombre, precio y subtotal ────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${it.unitPrice.toStringAsFixed(2)} c/u',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Subtotal: \$${(it.unitPrice * it.qty).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A6D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Contador cápsula + eliminar ────────────────────────────
                  Column(
                    children: [
                      _QtyStepperCapsule(
                        qty: it.qty,
                        onDecrement: () => cart.decrease(widget.index),
                        onIncrement: () => cart.setQty(widget.index, it.qty + 1),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => cart.removeAt(widget.index),
                        child: Text(
                          'Eliminar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Modificadores (chips) ────────────────────────────────────
              if (it.modifierLabels.isNotEmpty) ...[                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: -4,
                  children: it.modifierLabels
                      .map((lbl) => Chip(
                            label: Text(lbl, style: const TextStyle(fontSize: 12)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ],

              // ── Nota ────────────────────────────────────────────────────
              if (it.note != null && it.note!.trim().isNotEmpty) ...[                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        it.note!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
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

/// Cápsula con fondo gris claro que agrupa [−] cantidad [+]
class _QtyStepperCapsule extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyStepperCapsule({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón [-]
          _StepperBtn(icon: Icons.remove, onTap: onDecrement),
          // Número
          SizedBox(
            width: 36,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          // Botón [+]
          _StepperBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

/// Botón circular Rosa Mexicano con icono blanco
class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _mexicanPink,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class OrderCartSummary extends ProductsSelected {
  const OrderCartSummary({super.key});
}
