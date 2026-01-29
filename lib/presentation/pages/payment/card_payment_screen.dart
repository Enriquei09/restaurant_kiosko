import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';

import 'payment_success_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({super.key});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final tip = context.watch<TipModel>();

    final items = cart.items;

    final subtotal = items.fold<double>(0.0, (sum, it) => sum + (it.unitPrice * it.qty));
    final tipAmount = subtotal * tip.tipRate;
    final taxAmount = subtotal * cart.taxRate; // por ahora lo dejamos
    final total = subtotal + tipAmount + taxAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con tarjeta'),
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
                    'Total a cobrar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
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
                          : () async {
                              // Mostrar loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                final payment = context.read<PaymentModel>();
                                
                                // Preparar items para el backend
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

                                // Obtener configuración del restaurante
                                final restaurantId = await ConfigurationService.getRestaurantId();

                                // Enviar orden al backend
                                await ApiService.createOrder(
                                  restaurantId: restaurantId,
                                  clientName: payment.clientName,
                                  clientPhone: payment.clientPhone,
                                  paymentMethod: 'card_kiosk',
                                  items: orderItems,
                                  total: total,
                                  tip: tipAmount,
                                );

                                // Verificar si el widget aún está montado antes de usar context
                                if (!mounted) return;
                                
                                // Limpiar carrito y datos
                                context.read<CartModel>().clear();
                                context.read<PaymentModel>().clear();
                                
                                // Cerrar loading
                                Navigator.pop(context);

                                // Ir a pantalla de éxito
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaymentSuccessScreen(),
                                  ),
                                );
                              } catch (e) {
                                // Verificar si el widget aún está montado antes de usar context
                                if (!mounted) return;
                                
                                // Cerrar loading
                                Navigator.pop(context);
                                
                                // Mostrar error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al crear orden: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
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
