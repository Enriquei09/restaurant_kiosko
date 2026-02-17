import 'dart:async';
import 'package:flutter/material.dart';

/// Widget que detecta inactividad del usuario.
/// Después de [timeout] sin interacción, llama a [onInactive].
/// Cualquier toque, gesto o tecla reinicia el temporizador.
class InactivityDetector extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final VoidCallback onInactive;
  final bool enabled;

  const InactivityDetector({
    super.key,
    required this.child,
    required this.timeout,
    required this.onInactive,
    this.enabled = true,
  });

  @override
  State<InactivityDetector> createState() => InactivityDetectorState();
}

class InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void didUpdateWidget(InactivityDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled || widget.timeout != oldWidget.timeout) {
      _resetTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    if (!widget.enabled) return;

    _timer = Timer(widget.timeout, () {
      if (mounted && widget.enabled) {
        widget.onInactive();
      }
    });
  }

  /// Resetear externamente (ej: cuando el screensaver se cierra).
  void reset() => _resetTimer();

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
