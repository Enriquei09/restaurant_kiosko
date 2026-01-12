import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  double taxRate = 0.16;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, it) => sum + it.qty);


  void add(CartItem item) {
    final i = _items.indexWhere((e) =>
      e.productId == item.productId &&
      _eq(e.modifierIds, item.modifierIds) &&
      e.note == item.note
    );
    if (i >= 0) {
      _items[i] = _items[i].copyWith(qty: _items[i].qty + item.qty);
    } else {
      _items.add(item);
    }
    notifyListeners();
    save();
  }

  void decrease(int index) {
    final it = _items[index];
    if (it.qty > 1) {
      _items[index] = it.copyWith(qty: it.qty - 1);
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
    save();
  }

  void setQty(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(qty: qty);
    }
    notifyListeners();
    save();
  }

  void removeAt(int index) { _items.removeAt(index); notifyListeners(); save(); }
  void clear() { _items.clear(); notifyListeners(); save(); }

  double get subtotal => _items.fold(0, (s, it) => s + it.line);
  double get tax => double.parse((subtotal * taxRate).toStringAsFixed(2));
  double get total => subtotal + tax;

  // Persistencia
  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    final data = jsonEncode(_items.map((e) => e.toJson()).toList());
    await sp.setString('cart', data);
  }

  Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString('cart');
    if (data != null) {
      final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      _items..clear()..addAll(list.map(CartItem.fromJson));
      notifyListeners();
    }
  }

  bool _eq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final aa = [...a]..sort(), bb = [...b]..sort();
    for (var i = 0; i < aa.length; i++) if (aa[i] != bb[i]) return false;
    return true;
  }
  void replaceAt(int index, CartItem updated) {
  if (index < 0 || index >= _items.length) return;
  _items[index] = updated;
  notifyListeners();
  save();
}

}
