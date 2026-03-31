import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/tables_screen.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/providers/auth_provider.dart';

class WaiterScreen extends StatelessWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final userName = context.read<AuthProvider>().userName.isNotEmpty
        ? context.read<AuthProvider>().userName
        : (posProvider.currentCashRegister?.user?.name ?? 'Usuario');
    final userRole = context.read<AuthProvider>().roleName.isNotEmpty
        ? context.read<AuthProvider>().roleName
        : 'Mesero';
    
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
            const SizedBox(width: 12),
            // Avatar con menú de opciones
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  final auth = context.read<AuthProvider>();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                }
              },
              offset: const Offset(0, 50),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: Color(0xFFE91E63)),
                      SizedBox(width: 12),
                      Text('Salir'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE91E63),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
