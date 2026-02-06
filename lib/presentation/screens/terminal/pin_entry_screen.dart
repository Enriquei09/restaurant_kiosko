import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pos_provider.dart';
import '../../../models/cash_register_terminal.dart';
import '../../../service/api_service.dart';
import '../../../models/cash_register.dart';
import '../cashier/cashier_screen.dart';

class PinEntryScreen extends StatefulWidget {
  final CashRegisterTerminal terminal;

  const PinEntryScreen({Key? key, required this.terminal}) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String pin = '';
  bool isLoading = false;
  String errorMessage = '';
  bool obscurePin = true;

  void _addDigit(String digit) {
    if (pin.length < 6) {
      setState(() {
        pin += digit;
        errorMessage = '';
      });
    }
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
        errorMessage = '';
      });
    }
  }

  void _clearPin() {
    setState(() {
      pin = '';
      errorMessage = '';
    });
  }

  void _togglePinVisibility() {
    setState(() {
      obscurePin = !obscurePin;
    });
  }

  Future<void> _authenticatePin() async {
    if (pin.isEmpty) {
      setState(() {
        errorMessage = 'Ingresa el PIN del terminal';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      
      final response = await ApiService.authenticateTerminalPin(
        tenantId: posProvider.tenantId,
        restaurantId: posProvider.restaurantId,
        terminalNumber: widget.terminal.terminalNumber,
        pin: pin,
      );
      
      if (response['success'] == true) {
        // Verificar si ya hay una caja abierta
        if (response['has_open_register'] == true && response['cash_register'] != null) {
          // Ya hay una caja abierta, recuperarla
          final cashRegister = CashRegister.fromJson(response['cash_register']);
          posProvider.setCurrentCashRegister(cashRegister);
          
          // Mostrar mensaje informativo
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sesión de caja recuperada exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          
          // Navegar directamente a la pantalla de caja
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const CashierScreen(),
            ),
            (route) => false,
          );
        } else {
          // No hay caja abierta, proceder a abrir una nueva
          await _openCashRegister(response['terminal']);
        }
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'PIN incorrecto';
          isLoading = false;
          pin = '';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _openCashRegister(Map<String, dynamic> terminalData) async {
    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      
      // Mostrar diálogo para ingresar balance inicial
      final openingBalance = await _showOpeningBalanceDialog();
      if (openingBalance == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final response = await ApiService.openCashRegister(
        tenantId: posProvider.tenantId,
        restaurantId: posProvider.restaurantId,
        locationId: posProvider.locationId,
        userId: posProvider.userId,
        terminalId: terminalData['id'],
        openingBalance: openingBalance,
        openingNotes: 'Apertura automática desde terminal ${widget.terminal.terminalNumber}',
      );
      
      if (response['cash_register'] != null) {
        final cashRegister = CashRegister.fromJson(response['cash_register']);
        posProvider.setCurrentCashRegister(cashRegister);
        
        // Navegar a la pantalla de caja
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const CashierScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Error al abrir la caja';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al abrir la caja: $e';
        isLoading = false;
      });
    }
  }

  Future<double?> _showOpeningBalanceDialog() async {
    final controller = TextEditingController(text: '0.00');
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Balance Inicial - ${widget.terminal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el balance inicial de la caja:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Balance inicial',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final balance = double.tryParse(controller.text);
              if (balance != null && balance >= 0) {
                Navigator.of(context).pop(balance);
              }
            },
            child: const Text('Abrir Caja'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PIN - ${widget.terminal.name}'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTerminalInfo(),
                const SizedBox(height: 40),
                _buildPinDisplay(),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                _buildKeypad(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalInfo() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.point_of_sale,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              widget.terminal.terminalNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.terminal.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (widget.terminal.location?.isNotEmpty == true)
              Text(
                widget.terminal.location!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                obscurePin ? '•' * pin.length : pin,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: _togglePinVisibility,
              icon: Icon(
                obscurePin ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (int i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
          _buildKeypadButton('C', onPressed: _clearPin, color: Colors.orange),
          _buildKeypadButton('0'),
          _buildKeypadButton('←', onPressed: _removeDigit, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed ?? () => _addDigit(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white,
        foregroundColor: color != null ? Colors.white : Colors.blue.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading || pin.isEmpty ? null : _authenticatePin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Acceder'),
          ),
        ),
      ],
    );
  }
}