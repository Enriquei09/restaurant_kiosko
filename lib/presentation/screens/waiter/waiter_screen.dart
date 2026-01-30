import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/tables_screen.dart';

class WaiterScreen extends StatelessWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesero / Comedor'),
        backgroundColor: Colors.orange.shade800, // Distinct color for Waiter
        foregroundColor: Colors.white,
      ),
      body: const TablesScreen(), 
      // TablesScreen handles the logic: show tables -> click -> open order
    );
  }
}
