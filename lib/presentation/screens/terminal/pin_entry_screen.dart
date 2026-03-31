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
  // ── Constantes de diseño ──────────────────────────────────
  static const _kBg      = Color(0xFFF5F5F5);
  static const _kPink    = Color(0xFFE91E63);
  static const _kDark    = Color(0xFF212121);
  static const _kSub     = Color(0xFF757575);
  static const _kEmerald = Color(0xFF2E7D32);

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
        terminalId: terminalData['id'] as int,
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
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kEmerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  size: 22, color: _kEmerald),
            ),
            const SizedBox(width: 12),
            const Text('Balance Inicial',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: _kDark)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.terminal.name,
                style: const TextStyle(
                    fontSize: 13, color: _kSub, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter'),
              decoration: InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _kDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPink, width: 2),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar',
                style: TextStyle(
                    color: _kSub,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () {
              final text =
                  controller.text.isEmpty ? '0' : controller.text;
              final balance = double.tryParse(text);
              if (balance != null && balance >= 0) {
                Navigator.of(context).pop(balance);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Abrir Caja',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header blanco ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: _kSub),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Autenticación de Terminal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTerminalInfo(),
                        const SizedBox(height: 32),
                        _buildPinDisplay(),
                        if (errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 18, color: Colors.red.shade600),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        _buildKeypad(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
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

  Widget _buildTerminalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: _kEmerald, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kEmerald.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.point_of_sale_outlined,
                size: 28, color: _kEmerald),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.terminal.terminalNumber,
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.terminal.name,
                  style: const TextStyle(
                    color: _kSub,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                if (widget.terminal.location?.isNotEmpty == true)
                  Text(
                    widget.terminal.location!,
                    style: const TextStyle(
                      color: _kSub,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: pin.isEmpty
                ? Text(
                    'Ingresa tu PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter',
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pin.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: obscurePin
                            ? Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: _kPink,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Text(
                                pin[i],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: _kDark,
                                  fontFamily: 'Inter',
                                ),
                              ),
                      );
                    }),
                  ),
          ),
          InkWell(
            onTap: _togglePinVisibility,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                obscurePin
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _kSub,
                size: 20,
              ),
            ),
          ),
        ],
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (int i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
          _buildKeypadButton('C',
              onPressed: _clearPin,
              bgColor: const Color(0xFFFFF3E0),
              fgColor: Colors.orange.shade800),
          _buildKeypadButton('0'),
          _buildKeypadButton('←',
              onPressed: _removeDigit,
              bgColor: const Color(0xFFFFEBEE),
              fgColor: Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    VoidCallback? onPressed,
    Color? bgColor,
    Color? fgColor,
  }) {
    return Material(
      color: bgColor ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onPressed ?? () => _addDigit(text),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: fgColor ?? _kDark,
              fontFamily: 'Inter',
            ),
          ),
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
              foregroundColor: _kSub,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
            ),
            child: const Text('Cancelar',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading || pin.isEmpty ? null : _authenticatePin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kPink.withOpacity(0.4),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Acceder',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter')),
          ),
        ),
      ],
    );
  }
}