import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../models/cash_register.dart';
import '../../models/cash_register_terminal.dart';
import '../../service/api_service.dart';
import 'terminal/pin_entry_screen.dart';
import 'cashier/cashier_screen.dart';

class TerminalSelectionScreen extends StatefulWidget {
  const TerminalSelectionScreen({Key? key}) : super(key: key);

  @override
  State<TerminalSelectionScreen> createState() =>
      _TerminalSelectionScreenState();
}

class _TerminalSelectionScreenState extends State<TerminalSelectionScreen> {
  List<CashRegisterTerminal> terminals = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTerminals();
  }

  Future<void> _loadTerminals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);

      final response = await ApiService.getTerminals(
        tenantId: posProvider.tenantId,
        restaurantId: posProvider.restaurantId,
      );

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            terminals =
                (response['terminals'] as List)
                    .map((terminal) => CashRegisterTerminal.fromJson(terminal))
                    .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = response['message'] ?? 'Error al cargar terminales';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error de conexión: $e';
          isLoading = false;
        });
      }
    }
  }

  void _selectTerminal(CashRegisterTerminal terminal) {
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    posProvider.setSelectedTerminal(terminal);

    // ── Si el usuario ya está autenticado, saltar el PIN ──
    if (authProvider.isAuthenticated) {
      // Sincronizar datos del usuario autenticado al PosProvider
      posProvider.setUserId(authProvider.user!.id);
      posProvider.setRestaurantId(authProvider.user!.restaurantId);
      _handleDirectOpen(terminal);
      return;
    }

    // Sesión expirada o no hay login → ir a pantalla de PIN
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(terminal: terminal),
      ),
    );
  }

  // ── Flujo directo para usuario ya autenticado ──────────────

  Future<void> _handleDirectOpen(CashRegisterTerminal terminal) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);

      // ── 1. Consultar al backend si ya existe una caja abierta ──
      try {
        final currentRes = await ApiService.getCurrentCashRegister(
          userId: posProvider.userId,
          restaurantId: posProvider.restaurantId,
        );

        if (currentRes['cash_register'] != null) {
          // Ya hay caja abierta → recuperar y navegar directo al POS
          final cashRegister = CashRegister.fromJson(
            currentRes['cash_register'],
          );
          posProvider.setCurrentCashRegister(cashRegister);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sesión de caja recuperada exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const CashierScreen()),
              (route) => false,
            );
          }
          return;
        }
      } catch (_) {
        // Si falla la verificación, continuamos al flujo normal de apertura
      }

      // ── 2. No hay caja abierta → mostrar diálogo de balance inicial ──
      final openingBalance = await _showOpeningBalanceDialog(terminal);
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
        terminalId: terminal.id,
        openingBalance: openingBalance,
        openingNotes:
            'Apertura directa desde terminal ${terminal.terminalNumber}',
      );

      if (response['cash_register'] != null) {
        final cashRegister = CashRegister.fromJson(response['cash_register']);
        posProvider.setCurrentCashRegister(cashRegister);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CashierScreen()),
            (route) => false,
          );
        }
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

  Future<double?> _showOpeningBalanceDialog(
    CashRegisterTerminal terminal,
  ) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text('Balance Inicial - ${terminal.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ingresa el balance inicial de la caja:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Balance inicial',
                    hintText: '0.00',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.isEmpty ? '0' : controller.text;
                  final balance = double.tryParse(text);
                  if (balance != null && balance >= 0) {
                    Navigator.of(ctx).pop(balance);
                  }
                },
                child: const Text('Abrir Caja'),
              ),
            ],
          ),
    );
  }

  // ── Constantes de diseño ──────────────────────────────────
  static const _kBg = Color(0xFFF5F5F5);
  static const _kEmerald = Color(0xFF2E7D32); // verde esmeralda
  static const _kDark = Color(0xFF212121);
  static const _kSubtle = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Terminal',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kDark,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? _buildError()
                : _buildTerminalsList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: _kSubtle, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadTerminals,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kEmerald,
                side: const BorderSide(color: _kEmerald),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalsList() {
    if (terminals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay terminales disponibles',
              style: TextStyle(color: _kSubtle, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona tu terminal de trabajo',
            style: TextStyle(
              color: _kDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${terminals.length} terminal${terminals.length == 1 ? '' : 'es'} disponible${terminals.length == 1 ? '' : 's'}',
            style: TextStyle(color: _kSubtle, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 1.35,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: terminals.length,
              itemBuilder: (context, index) {
                return _buildTerminalCard(terminals[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalCard(CashRegisterTerminal terminal) {
    final bool available = terminal.isAvailable;
    final Color accent = available ? _kEmerald : Colors.orange.shade700;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => _selectTerminal(terminal),
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withOpacity(0.08),
        highlightColor: accent.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: accent, width: 5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icono + badge ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.point_of_sale_outlined,
                      size: 24,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      available ? 'Disponible' : 'Ocupada',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Número de terminal ──
              Text(
                terminal.terminalNumber,
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),

              // ── Nombre ──
              Text(
                terminal.name,
                style: TextStyle(color: _kSubtle, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Ubicación (si existe) ──
              if (terminal.location?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        terminal.location!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
