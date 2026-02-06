import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/tables_screen.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';

class KioskTableSelectionScreen extends StatelessWidget {
  const KioskTableSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu Mesa'),
        backgroundColor: const Color(0xFF3d5a80),
        foregroundColor: Colors.white,
      ),
      body: TablesScreen(
        onTableSelected: (ctx, table) {
           if (table.status == 'occupied') {
             // Optional: allow adding to occupied table for "Join a Party" scenario?
             // Or block it. User requested "seeing which are occupied", implies selection logic.
             // Let's allow selecting it, assuming the backend handles merging or adding new order.
             // But usually for a Kiosk, maybe we warn them.
             
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mesa ${table.name} seleccionada (Ocupada - Agregando orden)'),
                  duration: const Duration(seconds: 1),
                ),
             );
           }
           
           // Assign table to cart
           context.read<CartModel>().setTableId(table.id);
           
           // Navigate to Checkout
           Navigator.pushNamed(context, '/checkout');
        },
      ),
    );
  }
}
