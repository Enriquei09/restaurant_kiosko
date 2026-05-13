import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';

class KioskIdleScreen extends StatelessWidget {
  const KioskIdleScreen({super.key});

  static const List<String> _dishImages = [
    'assets/products_img/Tlacoyos.jpg',
    'assets/products_img/sopes.jpg',
    'assets/products_img/tostadas.jpg',
    'assets/img_comida/comida_mexicana.jpg',
  ];

  void _goToCategoriesMenu(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _goToCategoriesMenu(context),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider.builder(
              itemCount: _dishImages.length,
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 900),
                autoPlayCurve: Curves.easeInOut,
                enlargeCenterPage: false,
              ),
              itemBuilder: (context, index, realIndex) {
                return Image.asset(
                  _dishImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),

            // Capa para mejorar legibilidad del texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),

            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Toca para empezar tu orden',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
