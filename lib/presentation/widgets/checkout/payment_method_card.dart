import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';


class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({super.key});

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccione el tipo de pago',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Card(
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
                  'Metodo de pago',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                _PaymentOption(
                  icon: Icons.attach_money,
                  label: 'Efectivo',
                  selected: payment.isCash,
                  onTap: () => context.read<PaymentModel>().setMethod(PaymentMethod.cash),
                ),
                const SizedBox(height: 12),
                _PaymentOption(
                  icon: Icons.credit_card,
                  label: 'Tarjeta',
                  selected: payment.isCard,
                  onTap: () => context.read<PaymentModel>().setMethod(PaymentMethod.card),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              final payment = context.read<PaymentModel>();
              final cart = context.read<CartModel>();
              final tip = context.read<TipModel>();

              if (cart.items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tu carrito está vacío')),
                );
                return;
              }

              final subtotal = cart.items.fold<double>(0.0, (sum, it) => sum + (it.unitPrice * it.qty));
              final tipAmount = subtotal * tip.tipRate;
              final taxAmount = subtotal * cart.taxRate;
              final total = subtotal + tipAmount + taxAmount;

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Pago generado'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.method == PaymentMethod.cash
                            ? 'Método: Efectivo'
                            : 'Método: Tarjeta',
                      ),
                      const SizedBox(height: 12),
                      Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
                      Text('Propina: \$${tipAmount.toStringAsFixed(2)}'),
                      Text('IVA: \$${taxAmount.toStringAsFixed(2)}'),
                      const Divider(height: 18),
                      Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        // Aquí después conectamos: imprimir ticket / guardar orden / limpiar carrito
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pago confirmado ✅')),
                        );
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 15, 95, 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Generar pago', style: TextStyle(color: Colors.white)),
            
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF1B0D3A) : Colors.black.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
          color: selected ? const Color(0xFF1B0D3A).withOpacity(0.04) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Color(0xFF1B0D3A),
              ),
          ],
        ),
      ),
    );
  }
}
