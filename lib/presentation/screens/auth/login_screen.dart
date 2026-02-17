import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pos_provider.dart';
import '../../../providers/restaurant_provider.dart';

/// Pantalla de login con PIN numérico.
/// Recibe opcionalmente la ruta a la que redirigir después del login.
class LoginScreen extends StatefulWidget {
  final String? redirectRoute;
  final String? requiredPermission;
  final List<String>? requiredRoles;
  final String? roleName;

  const LoginScreen({
    super.key,
    this.redirectRoute,
    this.requiredPermission,
    this.requiredRoles,
    this.roleName,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;

  static const int _pinLength = 4;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  void _addDigit(String digit) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += digit;
        _error = null;
      });

      // Auto-submit cuando se completa el PIN
      if (_pin.length == _pinLength) {
        _submitPin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  void _clearPin() {
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _submitPin() async {
    if (_pin.length != _pinLength) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);

    final restaurantId = restaurantProvider.currentRestaurantId;
    if (restaurantId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No hay restaurante seleccionado';
        _pin = '';
      });
      return;
    }

    final success = await auth.loginWithPin(
      pin: _pin,
      restaurantId: restaurantId,
    );

    if (!mounted) return;

    if (success) {
      // Actualizar PosProvider con el userId
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      posProvider.setUserId(auth.user!.id);

      // Verificar permisos si se especificaron
      if (widget.requiredPermission != null &&
          !auth.hasPermission(widget.requiredPermission!)) {
        setState(() {
          _isLoading = false;
          _error =
              'Tu rol (${auth.roleName}) no tiene permiso para ${widget.roleName ?? "esta función"}';
          _pin = '';
        });
        // Logout porque no tiene permisos para lo solicitado
        await auth.logout();
        return;
      }

      if (widget.requiredRoles != null && !auth.hasRole(widget.requiredRoles!)) {
        setState(() {
          _isLoading = false;
          _error =
              'Tu rol (${auth.roleName}) no tiene acceso a ${widget.roleName ?? "esta función"}';
          _pin = '';
        });
        await auth.logout();
        return;
      }

      // Login exitoso — navegar
      if (widget.redirectRoute != null) {
        Navigator.pushReplacementNamed(context, widget.redirectRoute!);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = auth.error ?? 'PIN incorrecto';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(widget.roleName != null
            ? 'Acceso: ${widget.roleName}'
            : 'Iniciar Sesión'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'Ingresa tu PIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Introduce tu PIN de ${_pinLength} dígitos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Indicadores de PIN
                _buildPinIndicators(),
                const SizedBox(height: 16),

                // Error
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Loading
                if (_isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                ] else ...[
                  // Teclado numérico
                  _buildNumPad(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final filled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: filled ? 20 : 18,
          height: filled ? 20 : 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _primaryColor : Colors.transparent,
            border: Border.all(
              color: filled ? _primaryColor : Colors.grey.shade400,
              width: 2,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumPad() {
    return Column(
      children: [
        // Filas 1-2-3, 4-5-6, 7-8-9
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildNumKey('${row * 3 + col}'),
              ],
            ),
          ),
        // Fila: Clear, 0, Backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionKey(
              icon: Icons.clear_all,
              color: Colors.orange,
              onTap: _clearPin,
            ),
            _buildNumKey('0'),
            _buildActionKey(
              icon: Icons.backspace_outlined,
              color: Colors.red.shade400,
              onTap: _removeDigit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumKey(String digit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () => _addDigit(digit),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 80,
            height: 64,
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2939),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 80,
            height: 64,
            child: Center(
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
