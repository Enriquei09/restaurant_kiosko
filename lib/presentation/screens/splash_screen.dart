import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';

/// Pantalla de carga visual.
/// La logica de inicializacion y enrutamiento se maneja en _AppGate (main.dart).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
