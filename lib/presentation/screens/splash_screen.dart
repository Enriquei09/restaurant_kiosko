import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Inicializar en paralelo restaurante y sesión de auth
    await Future.wait([
      restaurantProvider.initialize(),
      authProvider.restoreSession(),
    ]);

    // Esperar un momento para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (restaurantProvider.hasSelection) {
        // Configurar el restaurantId en el cart para promociones
        final cart = Provider.of<CartModel>(context, listen: false);
        cart.setRestaurantId(restaurantProvider.currentRestaurantId!);

        // Ya tiene restaurante seleccionado, ir al home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // No tiene restaurante, ir a selección
        Navigator.pushReplacementNamed(context, '/restaurant-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = Provider.of<RestaurantProvider>(context).primaryColor;

    return Scaffold(
      backgroundColor: brandColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo THALO
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant,
                size: 80,
                color: brandColor,
              ),
            ),
            const SizedBox(height: 32),

            // Nombre THALO
            const Text(
              'THALO',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            const Text(
              'Sistema de Kioscos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
