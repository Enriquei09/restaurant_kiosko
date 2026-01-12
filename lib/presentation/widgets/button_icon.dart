import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/presentation/widgets/products_selected.dart';


class ButtonIcon extends StatelessWidget {
  const ButtonIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final totalItems = context.watch<CartModel>().totalItems;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filled(
          iconSize: 20,
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: Color.fromARGB(255, 247, 246, 246),
          ),
          onPressed: () {
            // Usa tu helper (barrierDismissible true)
            ProductsSelected.show(context);
          },
        ),

        // ✅ Badge contador
        if (totalItems > 0)
          Positioned(
            right: -2,
            top: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  '$totalItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
