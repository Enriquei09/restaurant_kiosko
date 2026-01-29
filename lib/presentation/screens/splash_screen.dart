import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';

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
      _checkRestaurantSelection();
    });
  }

  Future<void> _checkRestaurantSelection() async {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    await provider.initialize();

    // Esperar un momento para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (provider.hasSelection) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF3d5a80),
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
              child: const Icon(
                Icons.restaurant,
                size: 80,
                color: Color(0xFF3d5a80),
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
