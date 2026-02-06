import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/tables_screen.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';

class WaiterScreen extends StatelessWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final userName = posProvider.currentCashRegister?.user?.name ?? 'Usuario';
    final userRole = 'Mesero'; // TODO: Obtener del rol real del usuario
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Mesero / Comedor'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$userRole - $userName',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800, // Distinct color for Waiter
        foregroundColor: Colors.white,
      ),
      body: const TablesScreen(), 
      // TablesScreen handles the logic: show tables -> click -> open order
    );
  }
}
