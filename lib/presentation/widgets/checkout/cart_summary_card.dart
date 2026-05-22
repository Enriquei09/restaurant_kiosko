import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';

const Color _mexicanPink = Color(0xFFE91E63);

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cart  = context.watch<CartModel>();
    final tip   = context.watch<TipModel>();
    final items = cart.items;

    // Flujo de meseros: la mesa está asignada → sin propina
    final bool isWaiterFlow = cart.tableId != null;

    final subtotal  = items.fold<double>(0.0, (s, it) => s + it.unitPrice * it.qty);
    final tipAmount = isWaiterFlow ? 0.0 : subtotal * tip.tipRate;
    final taxAmount = subtotal * cart.taxRate;
    final total     = subtotal + tipAmount + taxAmount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: _mexicanPink, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tu pedido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D)),
                ),
                const Spacer(),
                Text(
                  '${items.length} ${items.length == 1 ? "producto" : "productos"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Tu carrito esta vacio', style: TextStyle(color: Colors.black38, fontSize: 14)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 16, color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                final it = items[i];
                return _SummaryItem(
                  name:      it.name,
                  price:     it.unitPrice,
                  qty:       it.qty,
                  modifiers: it.modifierLabels,
                  note:      it.note,
                );
              },
            ),
          // ── Sección de propina: solo en flujo de kiosko ──────────────
          if (!isWaiterFlow)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Propina', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TipChip(label: '0 %',  value: 0.0,  selected: tip.tipRate == 0.0),
                      _TipChip(label: '10 %', value: 0.10, selected: tip.tipRate == 0.10),
                      _TipChip(label: '15 %', value: 0.15, selected: tip.tipRate == 0.15),
                      _TipChip(label: '20 %', value: 0.20, selected: tip.tipRate == 0.20),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.fromLTRB(20, isWaiterFlow ? 8 : 16, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                _TotalRow(label: 'Subtotal',   value: _money(subtotal)),
                if (tipAmount > 0) _TotalRow(label: 'Propina', value: _money(tipAmount)),
                _TotalRow(label: 'IVA (16 %)', value: _money(taxAmount)),
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D))),
                    Text(_money(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E3A6D))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.name, required this.price, required this.qty, this.modifiers = const [], this.note});
  final String name;
  final double price;
  final int qty;
  final List<String> modifiers;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: _mexicanPink.withValues(alpha: 0.1), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$qty', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _mexicanPink)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D))),
              if (modifiers.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(modifiers.join(', '), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
              if (note != null && note!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(note!, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
        Text(_money(price * qty), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final double value;
  final bool selected;
  const _TipChip({required this.label, required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.read<TipModel>().setTipRate(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? _mexicanPink : Colors.grey[100],
          border: Border.all(color: selected ? _mexicanPink : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String _money(double v) => '\$${v.toStringAsFixed(2)}';
