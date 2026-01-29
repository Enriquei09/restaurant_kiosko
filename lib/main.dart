import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kitchen/kitchen_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/cashier_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/splash_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/restaurant_selection_screen.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';
import 'package:restaurant_kiosco/providers/restaurant_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()..restore()),
        ChangeNotifierProvider(create: (_) => PaymentModel()),
        ChangeNotifierProvider(create: (_) => TipModel()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
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
                    title: 'KIOSKO\nCliente',
                    icon: Icons.touch_app,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/menu'),
                  ),
                  const SizedBox(width: 32),
                  _buildOptionCard(
                    context,
                    title: 'CAJA\nCobro',
                    icon: Icons.point_of_sale,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/cashier'),
                  ),
                  const SizedBox(width: 32),
                  _buildOptionCard(
                    context,
                    title: 'COCINA\nPedidos',
                    icon: Icons.kitchen,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/kitchen'),
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
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        height: 300,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
