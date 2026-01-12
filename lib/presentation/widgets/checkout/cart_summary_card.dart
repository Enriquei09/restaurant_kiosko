import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Ajusta estos imports a tus rutas reales:
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final tip = context.watch<TipModel>();

    // ✅ Ajusta si tu CartItem usa otro nombre: title/name, price, qty, imageUrl, etc.
    final items = cart.items;

    // Subtotal real
    final subtotal = items.fold<double>(0.0, (sum, it) => sum + (it.unitPrice * it.qty));

    // Propina por porcentaje
    final tipAmount = subtotal * tip.tipRate;

    // Si quieres incluir tax/IVA del CartModel (ya tienes taxRate)
    final taxAmount = subtotal * cart.taxRate;

    // Total final (elige el que quieras)
    final total = subtotal + tipAmount + taxAmount;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de carrito',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // ✅ Lista real de productos
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'Tu carrito está vacío',
                        style: TextStyle(fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final it = items[index];
                        return _CartSummaryItem(
                          title: it.name, // si es it.title, cámbialo aquí
                          price: it.unitPrice,
                          qty: it.qty,
                          // image: it.image, // si tienes imagen
                        );
                      },
                    ),
            ),

            const Divider(height: 24),

            // ✅ Propina editable (chips)
            const Text(
              'Propina',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TipChip(label: '0%', value: 0.0, selected: tip.tipRate == 0.0),
                _TipChip(label: '10%', value: 0.10, selected: tip.tipRate == 0.10),
                _TipChip(label: '15%', value: 0.15, selected: tip.tipRate == 0.15),
                _TipChip(label: '20%', value: 0.20, selected: tip.tipRate == 0.20),
              ],
            ),

            const SizedBox(height: 14),

            // ✅ Totales
            _TotalRow(label: 'Subtotal', value: _money(subtotal)),
            _TotalRow(label: 'Propina', value: _money(tipAmount)),
            _TotalRow(label: 'IVA', value: _money(taxAmount)),
            const SizedBox(height: 8),
            _TotalRow(label: 'Total', value: _money(total), bold: true),
          ],
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final double value;
  final bool selected;

  const _TipChip({
    required this.label,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.read<TipModel>().setTipRate(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1B0D3A) : Colors.black.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
          color: selected ? const Color(0xFF1B0D3A).withOpacity(0.06) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1B0D3A) : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _CartSummaryItem extends StatelessWidget {
  final String title;
  final double price;
  final int qty;

  const _CartSummaryItem({
    required this.title,
    required this.price,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    final lineTotal = price * qty;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fastfood, size: 22),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Text(
            '$title\n${_money(lineTotal)}',
            style: const TextStyle(fontSize: 13),
          ),
        ),

        Text(
          'x$qty',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

String _money(double value) {
  // Formato simple sin intl, para que compile fácil
  return '\$${value.toStringAsFixed(2)}';
}
