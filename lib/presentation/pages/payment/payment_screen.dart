import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'cash_payment_screen.dart';
import 'card_payment_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final method = context.watch<PaymentModel>().method;

    // Renderiza la pantalla según el método
    if (method == PaymentMethod.cash) {
      return const CashPaymentScreen();
    }
    return const CardPaymentScreen();
  }
}
