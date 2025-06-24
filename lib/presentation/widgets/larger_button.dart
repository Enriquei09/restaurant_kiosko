import 'package:flutter/material.dart';

class LargeButton extends StatelessWidget {
  final bool enabled;
  const LargeButton({super.key, this.enabled = false});
  @override
  Widget build(BuildContext context) {
    //final VoidCallback? onPressed = enabled ? () {} : null;

    return Center(
      child: FilledButton(
        onPressed: () {
          DialogHelper.mostrarAlertaBasica(context);
        },
        
        style: ButtonStyle(
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 80),
          ),
          backgroundColor: WidgetStateProperty.all<Color>(
            const Color.fromARGB(255, 10, 10, 10),
          ),
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        ),
        child: Text("Agregar al Carrito"),
      ),
    );
  }
}


class DialogHelper {
  static Future<void> mostrarAlertaBasica(BuildContext context) {
    return showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });

        return AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green, size: 80.0),
          title: const Text('Pruducto Agregado'),
          content: SizedBox(
            width: 350,
            height: 50,            
          ),
          
        );
      },
    );
  }
}