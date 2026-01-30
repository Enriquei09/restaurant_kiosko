import 'dart:async';
import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatefulWidget {
  final int orderId;
  final String orderType; // 'Comer Aquí' o 'Para Llevar'
  final bool payAtCounter;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.orderType,
    this.payAtCounter = true,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  int _secondsRemaining = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _returnToHome();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _returnToHome() {
    // Pop until the first route (Home or Restaurant Selection)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Orden Recibida!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              
              const Text(
                'TU NÚMERO DE ORDEN ES:',
                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '#${widget.orderId}',
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B0D3A),
                ),
              ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    if (widget.payAtCounter) ...[
                      const Icon(Icons.payment, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Por favor, pasa a CAJA para realizar tu pago.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Menciona tu número de orden al cajero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ] else ...[
                      const Icon(Icons.timer, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'Tu orden se está preparando.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Espera a que te llamen por tu número #${widget.orderId}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _returnToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B0D3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Finalizar ($_secondsRemaining)',
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
