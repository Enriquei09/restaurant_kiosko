import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/presentation/widgets/edit_cart_item_dialog.dart';
import 'package:restaurant_kiosco/presentation/screens/checkout/checkout_screen.dart';

class ProductsSelected extends StatelessWidget {
  const ProductsSelected({super.key});

  /// Helper para abrir el modal permitiendo cerrar tocando afuera.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true, // tap fuera del modal = cerrar
      builder: (_) => const ProductsSelected(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Productos Seleccionados',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                      padding: const EdgeInsets.all(8),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _CartRow(index: i),
                    ),
            ),

            const Divider(height: 1),

            // Totales + acciones
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _total('Subtotal', cart.subtotal),
                  _total('IVA (16%)', cart.tax),
                  _total('Total', cart.total, bold: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                           onPressed: () {
                            Navigator.pop(context); // cierra el diálogo
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            );
                          },                          
                          
                          child: const Text('Confirmar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _total(String label, double value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w700) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
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

                  if (!isEditingQty) Text('x ${it.qty}'),
                  const SizedBox(width: 10),

                  // Botón Editar: también abre el selector
                  OutlinedButton(
                    onPressed: () => EditCartItemDialog.show(context, index: widget.index),
                    child: const Text('Editar'),
                  ),
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
