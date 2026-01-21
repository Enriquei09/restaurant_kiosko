import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';

class CashPaymentScreen extends StatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  final _controller = TextEditingController();

  double _parse(String v) => double.tryParse(v.replaceAll(',', '').trim()) ?? 0.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final tip = context.watch<TipModel>();

    final items = cart.items;
    final subtotal = items.fold<double>(0.0, (sum, it) => sum + (it.unitPrice * it.qty));
    final tipAmount = subtotal * tip.tipRate;
    final taxAmount = subtotal * cart.taxRate;
    final total = subtotal + tipAmount + taxAmount;

    final received = _parse(_controller.text);
    final change = received - total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago en efectivo'),
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
                  'Total a pagar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto recibido',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cambio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      change >= 0 ? '\$${change.toStringAsFixed(2)}' : 'Falta \$${(-change).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: change >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: items.isEmpty || change < 0
                        ? null
                        : () {
                            // ✅ Aquí luego: imprimir ticket / guardar orden
                            // cart.clear(); (si tienes método clear)
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pago en efectivo confirmado ✅')),
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
