import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_header.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;

  const BaseLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FA),
      body: Column(
        children: [
          // ✅ Header fijo
          const BuildHeader(),

          // ✅ Contenido que cambia
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
