import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/service/api_service.dart';

import 'payment_success_screen.dart';

class CashPaymentScreen extends StatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  bool _isLoading = false;

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
        title: const Text('Pagar en Caja'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 100, color: Colors.blue.shade800),
                  const SizedBox(height: 32),
                  const Text(
                    'Pagar en Mostrador',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total a pagar: \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Al confirmar, se generará tu orden. Deberás pasar a la caja para realizar el pago y que tu comida empiece a prepararse.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final payment = context.read<PaymentModel>();
                                
                                final orderItems = items.map((item) {
                                  return {
                                    'product_id': item.productId,
                                    'quantity': item.qty,
                                    'unit_price': item.unitPrice,
                                    'subtotal': item.unitPrice * item.qty,
                                    'notes': item.note,
                                    'modifiers': item.modifierIds,
                                  };
                                }).toList();

                                final posProvider = context.read<PosProvider>();
                                final restaurantId = posProvider.restaurantId;
                                final currentCashRegisterId = posProvider.currentCashRegister?.id;
                                final currentUserId = posProvider.userId;

                                final response = await ApiService.createOrder(
                                  restaurantId: restaurantId,
                                  clientName: payment.clientName,
                                  clientPhone: payment.clientPhone,
                                  paymentMethod: 'cash',
                                  cashRegisterId: currentCashRegisterId,
                                  waiterId: currentUserId,
                                  items: orderItems,
                                  total: total,
                                  tip: tipAmount,
                                );

                                if (mounted) {
                                  context.read<CartModel>().clear();
                                  context.read<PaymentModel>().clear();
                                  
                                  // Obtener ID de orden para mostrarlo (si la API lo devuelve en response['id'])
                                  // La respuesta de createOrder devuelve data['data'] que es el objeto Order
                                  final orderId = response['id'];
                                  final orderNumber = orderId != null ? '#$orderId' : '';

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentSuccessScreen(
                                        title: '¡Orden Creada!',
                                        message: 'Tu número de orden es $orderNumber.\nPor favor pasa a caja para pagar.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => _isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Generar Ticket de Pago', style: TextStyle(fontSize: 18)),
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
