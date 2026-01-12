import 'package:flutter/material.dart';

enum PaymentMethod { cash, card }

class PaymentModel extends ChangeNotifier {
  PaymentMethod _method = PaymentMethod.cash;

  PaymentMethod get method => _method;

  void setMethod(PaymentMethod value) {
    if (_method == value) return;
    _method = value;
    notifyListeners();
  }

  bool get isCash => _method == PaymentMethod.cash;
  bool get isCard => _method == PaymentMethod.card;
}
