import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';

class CardPaymentScreen extends StatelessWidget {
  const CardPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final tip = context.watch<TipModel>();

    final items = cart.items;
    final subtotal = items.fold<double>(0.0, (sum, it) => sum + (it.unitPrice * it.qty));
    final tipAmount = subtotal * tip.tipRate;
    final taxAmount = subtotal * cart.taxRate;
    final total = subtotal + tipAmount + taxAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con tarjeta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total a cobrar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Inserte o acerque la tarjeta al lector para procesar el pago.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: items.isEmpty
                        ? null
                        : () {
                            // ✅ Aquí luego: simular procesamiento / guardar orden / imprimir ticket
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pago con tarjeta confirmado ✅')),
                            );
                          },
                    child: const Text('Confirmar pago'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
