import 'package:flutter/material.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Placeholder lista
            _SummaryItemPlaceholder(),
            const SizedBox(height: 8),
            _SummaryItemPlaceholder(),
            const SizedBox(height: 8),
            _SummaryItemPlaceholder(),

            const Divider(height: 24),

            // Placeholder totales
            _TotalRow(label: 'Subtotal', value: '\$90.00'),
            _TotalRow(label: 'Propina', value: '\$5.00'),
            const SizedBox(height: 8),
            _TotalRow(
              label: 'Total',
              value: '\$95.00',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItemPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Producto (2pz)\n\$30.00',
            style: TextStyle(fontSize: 13),
          ),
        ),
        const Text('x2'),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
