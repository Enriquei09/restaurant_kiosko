import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/presentation/widgets/products_selected.dart';
import 'package:restaurant_kiosco/presentation/screens/checkout/checkout_screen.dart';

const Color _mexicanPink = Color(0xFFE4007C);


class ButtonIcon extends StatelessWidget {
  const ButtonIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final total = cart.total;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55E4007C),
            blurRadius: 30,
            offset: Offset(0, 12),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: null,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: _mexicanPink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
        label: Text(
          '\$${total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: () async {
          final goCheckout = await ProductsSelected.show(context);
          if (!context.mounted) return;

          if (goCheckout == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            );
          }
        },
      ),
    );
  }
}
