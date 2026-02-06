import 'package:flutter/material.dart';
import '../../service/api_service.dart';

class SupervisorAuthDialog extends StatefulWidget {
  final String title;
  final String description;
  final Function(int supervisorId) onAuthorized;

  const SupervisorAuthDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.onAuthorized,
  }) : super(key: key);

  @override
  State<SupervisorAuthDialog> createState() => _SupervisorAuthDialogState();
}

class _SupervisorAuthDialogState extends State<SupervisorAuthDialog> {
  String _pin = '';
  bool _isVerifying = false;
  String? _errorMessage;

  void _onNumberPressed(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
      
      // Auto-verificar cuando se alcanza el mínimo de 4 dígitos
      if (_pin.length >= 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = 'El PIN debe tener al menos 4 dígitos';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.verifySupervisorPin(
        pin: _pin,
        restaurantId: 1, // TODO: Obtener del contexto
      );
      
      if (response['success'] == true) {
        final supervisorId = response['data']['user']['id'] as int;
        if (mounted) {
          Navigator.of(context).pop();
          widget.onAuthorized(supervisorId);
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'PIN incorrecto';
          _pin = '';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al verificar PIN';
        _pin = '';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPinDisplay(),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildNumericKeypad(),
            const SizedBox(height: 16),
            if (_isVerifying)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onClear,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pin.length >= 4 ? _verifyPin : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Verificar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          bool isFilled = index < _pin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.blue : Colors.grey.shade300,
              border: Border.all(
                color: isFilled ? Colors.blue : Colors.grey.shade400,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 8),
        _buildKeypadRow(['', '0', 'C']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      children: numbers.map((num) {
        if (num.isEmpty) {
          return const Expanded(child: SizedBox());
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeypadButton(num),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String value) {
    bool isBackspace = value == 'C';
    
    return Material(
      color: isBackspace ? Colors.red.shade50 : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isVerifying
            ? null
            : () {
                if (isBackspace) {
                  _onBackspace();
                } else {
                  _onNumberPressed(value);
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.red.shade700,
                  size: 24,
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Función helper para mostrar el diálogo de autorización
Future<int?> showSupervisorAuthDialog({
  required BuildContext context,
  required String title,
  required String description,
}) async {
  int? supervisorId;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SupervisorAuthDialog(
      title: title,
      description: description,
      onAuthorized: (id) {
        supervisorId = id;
      },
    ),
  );
  
  return supervisorId;
}
