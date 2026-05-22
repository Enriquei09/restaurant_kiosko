import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/promotion.dart';
import '../service/api_service.dart';

enum OrderType { dineIn, takeAway }

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  double taxRate = 0.16;

  // ── Promotions ────────────────────────────────
  CartPromotionResult? _promotionResult;
  CartPromotionResult? get promotionResult => _promotionResult;

  bool _loadingPromotions = false;
  bool get loadingPromotions => _loadingPromotions;

  int? _restaurantId;

  void setRestaurantId(int id) {
    _restaurantId = id;
  }

  /// Sincronizar taxRate desde la configuración del restaurante.
  void setTaxRate(double rate) {
    // rate viene como porcentaje (ej: 16.0), convertir a decimal (0.16)
    taxRate = rate >= 1 ? rate / 100 : rate;
    notifyListeners();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, it) => sum + it.qty);

  int? _tableId;
  int? get tableId => _tableId;
  void setTableId(int? id) {
    _tableId = id;
    notifyListeners();
  }

  OrderType _orderType = OrderType.takeAway;
  OrderType get orderType => _orderType;
  void setOrderType(OrderType type) {
    _orderType = type;
    if (type == OrderType.takeAway) {
      _tableId = null;
    }
    notifyListeners();
  }


  void add(CartItem item) {
    final key = item.uniqueCombinationKey;
    final i = _items.indexWhere((e) => e.uniqueCombinationKey == key);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(qty: _items[i].qty + item.qty);
    } else {
      _items.add(item);
    }
    notifyListeners();
    save();
    validatePromotions();
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
    validatePromotions();
  }

  void setQty(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(qty: qty);
    }
    notifyListeners();
    save();
    validatePromotions();
  }

  void removeAt(int index) { _items.removeAt(index); notifyListeners(); save(); validatePromotions(); }
  void clear() { _items.clear(); _promotionResult = null; notifyListeners(); save(); }

  double get subtotal => _items.fold(0, (s, it) => s + it.line);
  double get promotionDiscount => _promotionResult?.totalDiscount ?? 0;
  double get subtotalAfterDiscount => subtotal - promotionDiscount;
  double get tax => double.parse((subtotalAfterDiscount * taxRate).toStringAsFixed(2));
  double get total => subtotalAfterDiscount + tax;

  /// ¿Este producto tiene una promo aplicada en el carrito?
  bool productHasActivePromo(int productId) {
    if (_promotionResult == null) return false;
    return _promotionResult!.applicable
        .any((p) => p.affectedProducts.contains(productId));
  }

  /// Obtener sugerencias de promo (ej: "agrega otro para 2x1").
  List<PromotionSuggestion> get promotionSuggestions =>
      _promotionResult?.suggestions ?? [];

  /// Promociones aplicadas al carrito.
  List<ApplicablePromotion> get appliedPromotions =>
      _promotionResult?.applicable ?? [];

  /// Validar promociones contra el API.
  Future<void> validatePromotions() async {
    if (_restaurantId == null || _items.isEmpty) {
      _promotionResult = null;
      notifyListeners();
      return;
    }

    _loadingPromotions = true;
    notifyListeners();

    try {
      final cartItems = _items.map((item) => {
        'product_id': item.productId,
        'quantity': item.qty,
        'price': item.unitPrice,
      }).toList();

      _promotionResult = await ApiService.validateCartPromotions(
        restaurantId: _restaurantId!,
        items: cartItems,
      );
    } catch (e) {
      debugPrint('Error validando promociones: $e');
      _promotionResult = null;
    }

    _loadingPromotions = false;
    notifyListeners();
  }

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

  void replaceAt(int index, CartItem updated) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = updated;
    notifyListeners();
    save();
  }

  

}
