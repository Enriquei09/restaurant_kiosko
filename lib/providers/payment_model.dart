import 'package:flutter/material.dart';

enum PaymentMethod { cash, card }

class PaymentModel extends ChangeNotifier {
  PaymentMethod _method = PaymentMethod.cash;
  String? _clientName;
  String? _clientPhone;

  PaymentMethod get method => _method;
  String? get clientName => _clientName;
  String? get clientPhone => _clientPhone;

  void setMethod(PaymentMethod value) {
    if (_method == value) return;
    _method = value;
    notifyListeners();
  }

  void setClientName(String? value) {
    _clientName = value;
    notifyListeners();
  }

  void setClientPhone(String? value) {
    _clientPhone = value;
    notifyListeners();
  }

  void clear() {
    _method = PaymentMethod.cash;
    _clientName = null;
    _clientPhone = null;
    notifyListeners();
  }

  void reset() => clear();

  bool get isCash => _method == PaymentMethod.cash;
  bool get isCard => _method == PaymentMethod.card;
}
