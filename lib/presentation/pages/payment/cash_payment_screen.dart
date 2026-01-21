import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';

import 'payment_success_screen.dart';

class CashPaymentScreen extends StatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  final TextEditingController _receivedCtrl = TextEditingController();

  double _parseMoney(String v) {
    final cleaned = v.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final tip = context.watch<TipModel>();

    final items = cart.items;

    final subtotal = items.fold<double>(0.0, (sum, it) => sum + (it.unitPrice * it.qty));
    final tipAmount = subtotal * tip.tipRate;
    final taxAmount = subtotal * cart.taxRate; // por ahora lo dejamos
    final total = subtotal + tipAmount + taxAmount;

    final received = _parseMoney(_receivedCtrl.text);
    final change = received - total;

    final canConfirm = items.isNotEmpty && change >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago en efectivo'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _receivedCtrl,
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
                      const Text(
                        'Cambio',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        canConfirm
                            ? '\$${change.toStringAsFixed(2)}'
                            : 'Falta \$${(-change).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: canConfirm ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: canConfirm
                          ? () {
                              // ✅ Confirmar pago: limpiar carrito y pasar a éxito
                              context.read<CartModel>().clear();

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaymentSuccessScreen(),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 15, 95, 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Confirmar pago',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
