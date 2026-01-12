import 'package:flutter/material.dart';

// Widgets (los crearemos en archivos separados)
import '../../widgets/checkout/payment_method_card.dart';
import '../../widgets/checkout/cart_summary_card.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FA), // fondo suave similar a tu maqueta
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Confirmacion de orden',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Layout principal
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 800;

                        if (isMobile) {
                          // ✅ En pantallas pequeñas: se apila (columna)
                          return const SingleChildScrollView(
                            child: Column(
                              children: [
                                PaymentMethodCard(),
                                SizedBox(height: 16),
                                CartSummaryCard(),
                              ],
                            ),
                          );
                        }

                        // ✅ En pantallas grandes: dos columnas
                        return const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: PaymentMethodCard(),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: CartSummaryCard(),
                            ),
                          ],
                        );
                      },
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
