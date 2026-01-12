import 'package:flutter/material.dart';

class TipModel extends ChangeNotifier {
  /// porcentaje (0.0 = 0%, 0.10 = 10%, etc.)
  double _tipRate = 0.0;

  double get tipRate => _tipRate;

  void setTipRate(double value) {
    if (_tipRate == value) return;
    _tipRate = value;
    notifyListeners();
  }
}
