import 'package:flutter/material.dart';
import '../../widgets/checkout/payment_method_card.dart';
import '../../widgets/checkout/cart_summary_card.dart';
import 'package:restaurant_kiosco/presentation/layout/base_layout.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ────────────────────────────────────────
              const Text(
                'Confirmar orden',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D0D0D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Revisa tu pedido antes de pagar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),

              // ── Layout principal ──────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 800;

                    if (isMobile) {
                      return const SingleChildScrollView(
                        child: Column(
                          children: [
                            CartSummaryCard(),
                            SizedBox(height: 16),
                            PaymentMethodCard(),
                          ],
                        ),
                      );
                    }

                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: PaymentMethodCard(),
                        ),
                        SizedBox(width: 20),
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
    );
  }
}










