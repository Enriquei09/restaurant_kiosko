import 'package:flutter/material.dart';
import '../../service/configuration_service.dart';

/// Widget del header que muestra información dinámica del restaurante
class RestaurantHeader extends StatefulWidget {
  final bool showLogo;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const RestaurantHeader({
    super.key,
    this.showLogo = true,
    this.height = 80,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<RestaurantHeader> createState() => _RestaurantHeaderState();
}

class _RestaurantHeaderState extends State<RestaurantHeader> {
  String _restaurantName = 'Cargando...';
  String _welcomeMessage = 'Bienvenido';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final name = await ConfigurationService.getRestaurantName();
      final welcome = await ConfigurationService.getConfigWithDefault(
        'ui.welcome.message',
        'Bienvenido a nuestro restaurante',
      );
      
      if (mounted) {
        setState(() {
          _restaurantName = name;
          _welcomeMessage = welcome;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restaurantName = 'Mi Restaurante';
          _welcomeMessage = 'Bienvenido';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Logo o icono del restaurante
              if (widget.showLogo) ...[
                FutureBuilder<String?>(
                  future: ConfigurationService.getConfig('ui.logo.url'),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          snapshot.data!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultLogo();
                          },
                        ),
                      );
                    }
                    return _buildDefaultLogo();
                  },
                ),
                const SizedBox(width: 16),
              ],

              // Información del restaurante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nombre del restaurante
                    _isLoading
                        ? Container(
                            width: 150,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : Text(
                            _restaurantName,
                            style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                    
                    const SizedBox(height: 4),
                    
                    // Mensaje de bienvenida
                    _isLoading
                        ? Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : Text(
                            _welcomeMessage,
                            style: TextStyle(
                              color: widget.textColor?.withValues(alpha: 0.8) ?? 
                                     Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),

              // Información adicional o acciones
              FutureBuilder<String>(
                future: _getCurrentTime(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? '',
                    style: TextStyle(
                      color: widget.textColor?.withValues(alpha: 0.7) ?? 
                             Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.restaurant,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Future<String> _getCurrentTime() async {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Widget simplificado para casos donde solo se necesita el nombre
class SimpleRestaurantTitle extends StatelessWidget {
  final TextStyle? style;

  const SimpleRestaurantTitle({
    super.key,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ConfigurationService.getRestaurantName(),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? 'Mi Restaurante',
          style: style ?? const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}