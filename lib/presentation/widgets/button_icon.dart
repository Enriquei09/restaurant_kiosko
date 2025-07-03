import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/products_selected.dart';

class ButtonIcon extends StatelessWidget {
  const ButtonIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      iconSize: 20,
      icon: const Icon(
        Icons.shopping_cart_outlined,
        color: Color.fromARGB(255, 245, 245, 245),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ProductsSelected();
          },
        ).then((resultado) {
          if (resultado != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Seleccionaste $resultado")));
          }
        });
      },
    );
  }
}
