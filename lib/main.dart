import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kitchen/kitchen_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/cashier_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/splash_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/restaurant_selection_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/terminal_selection_screen.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';
import 'package:restaurant_kiosco/providers/restaurant_provider.dart';
import 'package:restaurant_kiosco/providers/table_provider.dart';
import 'package:restaurant_kiosco/providers/cash_register_provider.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/presentation/screens/waiter/waiter_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/order_type_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/table_input_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/kiosk_table_selection_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/checkout/checkout_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/runner/runner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()..restore()),
        ChangeNotifierProvider(create: (_) => PaymentModel()),
        ChangeNotifierProvider(create: (_) => TipModel()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => CashRegisterProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'THALO Kiosk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3d5a80),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/menu': (context) => const MenuScreen(),
        '/kitchen': (context) => const KitchenScreen(),
        '/cashier': (context) => const CashierScreen(),
        '/terminal-selection': (context) => const TerminalSelectionScreen(),
        '/waiter': (context) => const WaiterScreen(),
        '/runner': (context) => const RunnerScreen(),
        '/kiosk/order-type': (context) => const OrderTypeScreen(),
        '/kiosk/table-input': (context) => const TableInputScreen(),
        '/kiosk/table-selection': (context) => const KioskTableSelectionScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/restaurant-selection': (context) => const RestaurantSelectionScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema POS - Restaurante'),
        backgroundColor: const Color(0xFF3d5a80),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Selecciona tu Rol',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionCard(
                    context,
                    title: 'KIOSKO',
                    subtitle: 'Cliente',
                    icon: Icons.touch_app,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/kiosk/order-type'),
                  ),
                  const SizedBox(width: 24),
                  _buildOptionCard(
                    context,
                    title: 'MESERO',
                    subtitle: 'Mesas',
                    icon: Icons.table_restaurant,
                    color: Colors.orange.shade800,
                    onTap: () => Navigator.pushNamed(context, '/waiter'),
                  ),
                  const SizedBox(width: 24),
                  _buildOptionCard(
                    context,
                    title: 'COCINA',
                    subtitle: 'Pedidos',
                    icon: Icons.kitchen,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/kitchen'),
                  ),
                  const SizedBox(width: 24),
                  _buildOptionCard(
                    context,
                    title: 'CAJA',
                    subtitle: 'Cobro',
                    icon: Icons.point_of_sale,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/terminal-selection'),
                  ),
                  const SizedBox(width: 24),
                  _buildOptionCard(
                    context,
                    title: 'ENTREGAR',
                    subtitle: 'Runner',
                    icon: Icons.delivery_dining,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/runner'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180, // Slightly smaller to fit 4
        height: 220,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
