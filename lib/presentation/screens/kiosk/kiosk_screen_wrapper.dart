import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/restaurant_provider.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/screensaver_screen.dart';
import 'package:restaurant_kiosco/presentation/widgets/inactivity_detector.dart';

/// Wrapper para pantallas del kiosk que añade detección de inactividad
/// y muestra el screensaver cuando el usuario deja de interactuar.
///
/// Uso:
/// ```dart
/// KioskScreenWrapper(
///   child: MenuScreen(),
/// )
/// ```
class KioskScreenWrapper extends StatefulWidget {
  final Widget child;

  const KioskScreenWrapper({super.key, required this.child});

  @override
  State<KioskScreenWrapper> createState() => _KioskScreenWrapperState();
}

class _KioskScreenWrapperState extends State<KioskScreenWrapper> {
  bool _showScreensaver = false;
  final GlobalKey<InactivityDetectorState> _detectorKey = GlobalKey();

  void _activateScreensaver() {
    if (mounted) {
      setState(() => _showScreensaver = true);
    }
  }

  void _dismissScreensaver() {
    if (mounted) {
      setState(() => _showScreensaver = false);
      _detectorKey.currentState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final screensaverConfig = restaurantProvider.screensaverConfig;
    final enabled = restaurantProvider.screensaverEnabled;
    final timeout = restaurantProvider.screensaverTimeout;

    if (_showScreensaver && enabled) {
      return ScreensaverScreen(
        config: screensaverConfig,
        onDismiss: _dismissScreensaver,
      );
    }

    return InactivityDetector(
      key: _detectorKey,
      timeout: timeout,
      enabled: enabled,
      onInactive: _activateScreensaver,
      child: widget.child,
    );
  }
}
