import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pos_provider.dart';
import '../../../providers/restaurant_provider.dart';

// ─── Constantes de diseño ────────────────────────────────────────────────────
const _kBg            = Color(0xFFF8F9FA);
const _kPinActive     = Color(0xFFE91E63); // Rosa Mexicano
const _kPinError      = Color(0xFFEF4444);
const _kNumText       = Color(0xFF374151); // Gris oscuro
const _kSubtitle      = Color(0xFF6B7280);
const _kKeyBg         = Colors.white;
const int _pinLength  = 4;

/// Pantalla de login con PIN numérico — diseño premium.
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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String  _pin       = '';
  bool    _isLoading = false;
  String? _error;
  bool    _shaking   = false;

  // Shake animation
  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Oscilación: 0 → 1 → -1 → 1 → -1 → 0  (vibración)
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  void _addDigit(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
      _shaking = false;
    });
    if (_pin.length == _pinLength) _submitPin();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
      _shaking = false;
    });
  }

  void _clearPin() => setState(() {
    _pin = '';
    _error = null;
    _shaking = false;
  });

  /// Lanza la animación shake + colorea rojo 1 s
  Future<void> _triggerShake() async {
    setState(() => _shaking = true);
    _shakeCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _shaking = false);
  }

  Future<void> _submitPin() async {
    if (_pin.length != _pinLength) return;

    setState(() { _isLoading = true; _error = null; });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rp   = Provider.of<RestaurantProvider>(context, listen: false);

    final restaurantId = rp.currentRestaurantId;
    if (restaurantId == null) {
      setState(() { _isLoading = false; _error = 'No hay restaurante seleccionado'; _pin = ''; });
      _triggerShake();
      return;
    }

    final success = await auth.login(_pin, restaurantId);
    if (!mounted) return;

    if (success) {
      // Actualizar PosProvider
      final pos = Provider.of<PosProvider>(context, listen: false);
      pos.setUserId(auth.user!.id);
      if (rp.currentRestaurantId != null) pos.setRestaurantId(rp.currentRestaurantId!);
      if (rp.currentTenantId != null) pos.setTenantId(rp.currentTenantId!);

      // Verificar permisos
      if (widget.requiredPermission != null && !auth.hasPermission(widget.requiredPermission!)) {
        setState(() {
          _isLoading = false;
          _error = 'Tu rol (${auth.roleName}) no tiene permiso para ${widget.roleName ?? "esta función"}';
          _pin = '';
        });
        _triggerShake();
        await auth.logout();
        return;
      }
      if (widget.requiredRoles != null && !auth.hasRole(widget.requiredRoles!)) {
        setState(() {
          _isLoading = false;
          _error = 'Tu rol (${auth.roleName}) no tiene acceso a ${widget.roleName ?? "esta función"}';
          _pin = '';
        });
        _triggerShake();
        await auth.logout();
        return;
      }

      // Navegar
      if (widget.redirectRoute != null) {
        Navigator.pushReplacementNamed(context, widget.redirectRoute!);
      } else {
        _navigateByRole(auth);
      }
    } else {
      setState(() { _isLoading = false; _error = auth.error ?? 'PIN incorrecto'; _pin = ''; });
      _triggerShake();
    }
  }

  void _navigateByRole(AuthProvider auth) {
    switch (auth.roleName.toLowerCase()) {
      case 'cashier' || 'cajero':
        Navigator.pushReplacementNamed(context, '/cashier');
      case 'waiter' || 'mesero':
        Navigator.pushReplacementNamed(context, '/waiter');
      case 'cook' || 'cocinero':
        Navigator.pushReplacementNamed(context, '/kitchen');
      case 'bartender':
        Navigator.pushReplacementNamed(context, '/kitchen');
      case 'manager' || 'gerente' || 'admin' || 'super_admin':
        Navigator.pushReplacementNamed(context, '/home');
      default:
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final brandColor = restaurantProvider.primaryColor;
    final restaurantName = restaurantProvider.config.displayName.isNotEmpty
        ? restaurantProvider.config.displayName
        : 'THALO';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ────────────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.restaurant, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // ── Nombre del restaurante ─────────────────────
                  Text(
                    restaurantName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.roleName != null
                        ? 'Acceso: ${widget.roleName}'
                        : 'Ingresa tu PIN',
                    style: const TextStyle(fontSize: 14, color: _kSubtitle),
                  ),
                  const SizedBox(height: 36),

                  // ── Círculos PIN (con shake) ───────────────────
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      );
                    },
                    child: _buildPinCircles(),
                  ),
                  const SizedBox(height: 20),

                  // ── Error ──────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _error != null
                        ? Padding(
                            key: ValueKey(_error),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: _kPinError, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: _kPinError, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-error')),
                  ),

                  // ── Loading o Teclado ──────────────────────────
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: _kPinActive),
                    )
                  else
                    _buildNumPad(),

                  const SizedBox(height: 40),

                  // ── Botón volver ───────────────────────────────
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _kSubtitle),
                    label: const Text('Volver', style: TextStyle(color: _kSubtitle)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── PIN circles ────────────────────────────────────────────────────────────

  Widget _buildPinCircles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final filled = i < _pin.length;
        final circleColor = _shaking
            ? _kPinError
            : (filled ? _kPinActive : Colors.transparent);
        final borderColor = _shaking
            ? _kPinError
            : (filled ? _kPinActive : const Color(0xFFD1D5DB));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: filled && !_shaking
                ? [BoxShadow(color: _kPinActive.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
        );
      }),
    );
  }

  // ── Numpad ─────────────────────────────────────────────────────────────────

  Widget _buildNumPad() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _numKey('${row * 3 + col}'),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionKey(icon: Icons.clear_all_rounded, onTap: _clearPin),
            _numKey('0'),
            _actionKey(icon: Icons.backspace_outlined, onTap: _removeDigit),
          ],
        ),
      ],
    );
  }

  Widget _numKey(String digit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () => _addDigit(digit),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kKeyBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _kNumText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: _kSubtitle, size: 24),
        ),
      ),
    );
  }
}
