// presentation/widgets/large_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/models/cart_item.dart';
import 'package:restaurant_kiosco/presentation/widgets/products_selected.dart';

class LargeButton extends StatelessWidget {
  final int productId;
  final String name;
  final double price;
  final List<int> modifierIds;
   final List<String> modifierLabels;
  final String? note;
  final String? imagePath;
  final int qty;
  final bool openCartAfterAdd;
  final bool closeCurrentDialog;
  final String? buttonText;
  final Color backgroundColor;
  final double minHeight;
  final double fontSize;

  const LargeButton({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    this.modifierIds = const [],
     this.modifierLabels = const [], 
    this.note,
    this.imagePath,
    this.qty = 1,
    this.openCartAfterAdd = true,
    this.closeCurrentDialog = false,
    this.buttonText,
    this.backgroundColor = const Color(0xFFE91E63),
    this.minHeight = 60,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () async {
          // 1) Agregar al carrito (Provider)
          context.read<CartModel>().add(
            CartItem(
              productId: productId,
              name: name,
              unitPrice: price,
              qty: qty,
              modifierIds: modifierIds,
              modifierLabels: modifierLabels,
              note: note,
              imagePath: imagePath,
            ),
          );
        // 2) cierra el diálogo actual (selector) si se pidió
        if (closeCurrentDialog && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
          // pequeña pausa para evitar usar un context ya desmontado
          await Future.delayed(const Duration(milliseconds: 50));
        }
          // 3) Feedback y/o abrir modal
          if (openCartAfterAdd && context.mounted) {
            ProductsSelected.show(context);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Producto agregado')));
          }
        },
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          buttonText ?? 'Agregar al carrito',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
