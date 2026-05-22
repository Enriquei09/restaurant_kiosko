import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'cash_payment_screen.dart';
import 'card_payment_screen.dart';

class PaymentScreen extends StatelessWidget {
  final int? tableId; // tableId cuando está en flujo de mesero
  
  const PaymentScreen({super.key, this.tableId});

  @override
  Widget build(BuildContext context) {
    final method = context.watch<PaymentModel>().method;

    // Renderiza la pantalla según el método
    if (method == PaymentMethod.cash) {
      return CashPaymentScreen(tableId: tableId);
    }
    return CardPaymentScreen(tableId: tableId);
  }
}
