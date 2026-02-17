import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_kiosco/models/screensaver_config.dart';

/// Pantalla de reposo (screensaver) con imágenes rotativas.
/// Al tocar la pantalla en cualquier punto, regresa al menú.
class ScreensaverScreen extends StatefulWidget {
  final ScreensaverConfig config;
  final VoidCallback onDismiss;

  const ScreensaverScreen({
    super.key,
    required this.config,
    required this.onDismiss,
  });

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.value = 1.0;

    // Iniciar rotación automática
    if (widget.config.images.length > 1) {
      _timer = Timer.periodic(
        Duration(seconds: widget.config.intervalSeconds),
        (_) => _nextImage(),
      );
    }
  }

  void _nextImage() {
    _animController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.config.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.config.images.isEmpty) {
      return GestureDetector(
        onTap: widget.onDismiss,
        child: const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'Toca para continuar',
              style: TextStyle(color: Colors.white54, fontSize: 24),
            ),
          ),
        ),
      );
    }

    final image = widget.config.images[_currentIndex];
    final transition = widget.config.transition;

    return GestureDetector(
      onTap: widget.onDismiss,
      onPanDown: (_) => widget.onDismiss(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen actual con transición
            _buildAnimatedImage(image, transition),

            // Indicador sutil de toque
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: 0.5,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Toca la pantalla para ordenar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Indicador de imagen (dots)
            if (widget.config.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.config.images.length,
                    (i) => Container(
                      width: i == _currentIndex ? 10 : 6,
                      height: i == _currentIndex ? 10 : 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedImage(ScreensaverImage image, String transition) {
    final child = CachedNetworkImage(
      imageUrl: image.displayUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
        ),
      ),
    );

    switch (transition) {
      case 'fade':
        return FadeTransition(
          opacity: _animation,
          child: child,
        );
      case 'zoom':
        return ScaleTransition(
          scale: Tween(begin: 1.05, end: 1.0).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: child,
          ),
        );
      case 'slide':
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(_animation),
          child: child,
        );
      default:
        return FadeTransition(
          opacity: _animation,
          child: child,
        );
    }
  }
}
