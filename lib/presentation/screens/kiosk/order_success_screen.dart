import 'dart:async';
import 'package:flutter/material.dart';

class SuccessOrderScreen extends StatefulWidget {
  final int orderId;

  const SuccessOrderScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<SuccessOrderScreen> createState() => _SuccessOrderScreenState();
}

class _SuccessOrderScreenState extends State<SuccessOrderScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brandPink = Color(0xFFE4007C);

  int _secondsRemaining = 10;
  Timer? _countdownTimer;
  Timer? _autoResetTimer;
  late final AnimationController _checkController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      }
    });

    _autoResetTimer = Timer(const Duration(seconds: 10), _returnToHome);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoResetTimer?.cancel();
    _checkController.dispose();
    super.dispose();
  }

  void _returnToHome() {
    if (!mounted) return;
    // Pop until the first route (Home or Restaurant Selection)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brandPink.withOpacity(0.12),
                    border: Border.all(
                      color: _brandPink.withOpacity(0.35),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _brandPink,
                    size: 110,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                '¡Tu orden se ha enviado a cocina!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF251A2C),
                ),
              ),

              const SizedBox(height: 36),

              const Text(
                'NÚMERO DE ORDEN',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 1.4,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                '#${widget.orderId}',
                style: const TextStyle(
                  fontSize: 104,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: _brandPink,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: const Text(
                  'Mantente atento a las pantallas para recoger tu pedido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2A31),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _returnToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Volver al inicio ($_secondsRemaining)',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderSuccessScreen extends SuccessOrderScreen {
  const OrderSuccessScreen({
    super.key,
    required int orderId,
    String? orderType,
    bool payAtCounter = true,
  }) : super(orderId: orderId);
}
