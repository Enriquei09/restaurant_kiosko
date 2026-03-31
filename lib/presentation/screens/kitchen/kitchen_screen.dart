import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';
import 'package:restaurant_kiosco/service/reverb_service.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/providers/auth_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with TickerProviderStateMixin {
  List<KitchenOrder> orders = [];
  Map<String, int> counts = {};
  bool isLoading = true;
  String? error;
  Timer? _pollTimer;
  Timer? _elapsedTimer;
  Timer? _syncTimer;
  int _secondsSinceSync = 0;
  String selectedTab = 'active';

  // ── WebSocket (Reverb) ──
  ReverbService? _reverb;
  bool _wsConnected = false;
  String _syncLabel = 'Conectando…';

  // ── Animación para nuevas órdenes ──
  // IDs de órdenes que acaban de llegar por WS para marcar animación
  final Set<int> _freshOrderIds = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _loadOrders();
    _initWebSocket();
    // Polling como fallback (cada 15s en vez de 10 ya que WS es primario)
    _pollTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _loadOrders());
    _elapsedTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _secondsSinceSync > 0) {
        setState(() => _secondsSinceSync++);
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _reverb?.dispose();
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  // ── Iniciar conexión WebSocket a Reverb ──
  Future<void> _initWebSocket() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final restaurantId = await ConfigurationService.getRestaurantId();

    _reverb = ReverbService(
      token: token,
      restaurantId: restaurantId,
      onConnected: () {
        if (mounted) {
          setState(() {
            _wsConnected = true;
            _syncLabel = 'Recién';
            _secondsSinceSync = 0;
          });
        }
      },
      onDisconnected: () {
        if (mounted) setState(() => _wsConnected = false);
      },
      onEvent: _handleReverbEvent,
      onError: (err) {
        debugPrint('[KDS] Reverb error: $err');
      },
    );

    await _reverb!.connect();
  }

  // ── Manejar eventos que llegan por WebSocket ──
  void _handleReverbEvent(String event, Map<String, dynamic> data) {
    if (!mounted) return;

    if (event == 'OrderCreated' || event == '.OrderCreated') {
      final orderData = data['order'] as Map<String, dynamic>?;
      if (orderData == null) return;

      // Solo nos interesan órdenes activas (confirmed/preparing) en el tab activo
      final status = orderData['status'] as String? ?? '';
      if (selectedTab == 'active' &&
          (status == 'confirmed' || status == 'preparing')) {
        // Construir KitchenOrder desde el payload del evento
        final newOrder = KitchenOrder.fromJson({
          ...orderData,
          'order_details': orderData['items'] ?? [],
        });

        // Evitar duplicados
        if (orders.any((o) => o.id == newOrder.id)) return;

        setState(() {
          orders.insert(0, newOrder);
          _freshOrderIds.add(newOrder.id);
          // Actualizar conteos
          counts[status] = (counts[status] ?? 0) + 1;
          _secondsSinceSync = 0;
          _syncLabel = 'Recién';
        });

        // Limpiar marca de "nuevo" después de la animación
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _freshOrderIds.remove(newOrder.id));
        });
      } else {
        // Si no es el tab activo, simplemente recargar
        _loadOrders();
      }
    }
  }

  Future<void> _loadOrders() async {
    try {
      // Map 'active' to statuses that are 'En Curso'
      String statusFilter = selectedTab == 'active' 
          ? 'confirmed,preparing' 
          : 'ready,delivered'; 
      
      final restaurantId = await ConfigurationService.getRestaurantId();
      final response = await ApiService.fetchKitchenOrders(
        restaurantId: restaurantId,
        status: statusFilter,
      );

      if (mounted) {
        setState(() {
          orders = response.orders;
          counts = response.counts;
          isLoading = false;
          error = null;
          _secondsSinceSync = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }
  
   Future<void> _advanceOrder(int orderId) async {
      // Move to next state: confirmed → preparing → ready
      try {
        // Find the current order's status to determine next state
        final currentOrder = orders.firstWhere(
          (o) => o.id == orderId,
          orElse: () => orders.first,
        );
        
        String nextStatus;
        if (currentOrder.status == 'confirmed') {
          nextStatus = 'preparing';
        } else if (currentOrder.status == 'preparing') {
          nextStatus = 'ready';
        } else {
          nextStatus = 'ready'; // fallback
        }
        
        await ApiService.updateOrderStatus(orderId: orderId, status: nextStatus);
        _loadOrders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos conteos para los tabs
    // Active = confirmed + preparing
    // Completed = ready + delivered
    final activeCount = (counts['confirmed'] ?? 0) + (counts['preparing'] ?? 0);
    final completedCount = (counts['ready'] ?? 0) + (counts['delivered'] ?? 0);
    
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final userName = context.read<AuthProvider>().userName.isNotEmpty
        ? context.read<AuthProvider>().userName
        : (posProvider.currentCashRegister?.user?.name ?? 'Usuario');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header ──
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Reloj
                  Text(
                    _formatTime(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cocina',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  // Selector con pastillas redondeadas
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'active',
                        label: Text(
                          activeCount > 0
                              ? 'En Curso ($activeCount)'
                              : 'En Curso',
                        ),
                      ),
                      ButtonSegment(
                        value: 'completed',
                        label: Text(
                          completedCount > 0
                              ? 'Completados ($completedCount)'
                              : 'Completados',
                        ),
                      ),
                    ],
                    selected: {selectedTab},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        selectedTab = newSelection.first;
                        isLoading = true;
                      });
                      _loadOrders();
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF1B1B1B);
                        }
                        return Colors.grey.shade100;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Colors.black54;
                      }),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      side: WidgetStateProperty.all(BorderSide.none),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // ── Status de sincronización + WS ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Punto de estado WS
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _wsConnected
                              ? Colors.green.shade400
                              : Colors.orange.shade400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _secondsSinceSync < 15
                            ? Icons.cloud_done_rounded
                            : Icons.sync_rounded,
                        size: 14,
                        color: _secondsSinceSync < 15
                            ? Colors.green.shade400
                            : Colors.orange.shade400,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _secondsSinceSync < 3
                            ? _syncLabel
                            : 'Hace ${_secondsSinceSync}s',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // ── Avatar con menú: Cambiar Cocinero + Salir ──
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'switch') {
                        _showQuickSwitchDialog(context);
                      } else if (value == 'logout') {
                        final auth = context.read<AuthProvider>();
                        await auth.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      }
                    },
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          userName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF2196F3)),
                            SizedBox(width: 12),
                            Text('Cambiar Cocinero'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 20, color: Color(0xFFE91E63)),
                            SizedBox(width: 12),
                            Text('Salir'),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE91E63),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Body ──
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive: adaptar tarjetas al ancho disponible
                          final w = constraints.maxWidth;
                          final maxExtent = w >= 1200
                              ? 260.0  // Desktop / tablet landscape → ~5 cols
                              : w >= 800
                                  ? 240.0  // Tablet portrait → ~3-4 cols
                                  : 200.0; // Móvil → 2 cols
                          final aspect = w >= 800 ? 0.55 : 0.50;

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: maxExtent,
                                childAspectRatio: aspect,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                            final order = orders[index];
                            final isFresh = _freshOrderIds.contains(order.id);
                            return AnimatedScale(
                              scale: isFresh ? 1.0 : 1.0,
                              duration: const Duration(milliseconds: 400),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutBack,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isFresh
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFE91E63)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: KitchenOrderCard(
                                  order: order,
                                  onAdvance: () => _advanceOrder(order.id),
                                ),
                              ),
                            );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  // ── Quick Switch Dialog ──
  Future<void> _showQuickSwitchDialog(BuildContext ctx) async {
    final pinController = TextEditingController();
    String? dialogError;

    await showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (sbCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      color: Color(0xFFE91E63), size: 24),
                  SizedBox(width: 10),
                  Text('Cambiar Cocinero',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ingresa el PIN del nuevo cocinero para cambiar de usuario sin cerrar sesión.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • •',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 28,
                        letterSpacing: 12,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFE91E63), width: 2),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancelar',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (pin.length < 4) {
                      setDialogState(() {
                        dialogError = 'El PIN debe tener al menos 4 dígitos';
                      });
                      return;
                    }
                    try {
                      final auth = ctx.read<AuthProvider>();
                      final restaurantId =
                          await ConfigurationService.getRestaurantId();
                      final ok = await auth.login(pin, restaurantId);
                      if (ok) {
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Bienvenido, ${auth.userName}'),
                              backgroundColor: const Color(0xFFE91E63),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          dialogError =
                              auth.error ?? 'PIN inválido o sin permiso';
                        });
                      }
                    } catch (e) {
                      setDialogState(() {
                        dialogError = 'Error: $e';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cambiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

}

class KitchenOrderCard extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback onAdvance;

  const KitchenOrderCard({
    super.key,
    required this.order,
    required this.onAdvance,
  });

  /// Color de urgencia según tiempo transcurrido (semáforo de cocina)
  Color _urgencyColor(int elapsed) {
    if (elapsed >= 11) return Colors.red.shade600;     // 🔴 Urgente
    if (elapsed >= 6)  return Colors.orange.shade700;  // 🟠 Espera
    return const Color(0xFF43A047);                    // 🟢 Nuevo
  }

  /// Etiqueta textual del semáforo
  String _urgencyLabel(int elapsed) {
    if (elapsed >= 11) return 'URGENTE';
    if (elapsed >= 6)  return 'ESPERA';
    return 'NUEVO';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = order.elapsedMinutes;
    final color = _urgencyColor(elapsed);
    final timeStr =
        '${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Borde superior grueso de color (urgencia) ──
          Container(height: 6, color: color),

          // ── Cabecera info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Orden + hora
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#Orden ${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge de minutos transcurridos + etiqueta
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${elapsed}m',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _urgencyLabel(elapsed),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Tipo de orden
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.orderTypeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // ── Items del pedido ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  if (index > 5) {
                    if (index == 6) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${order.items.length - 6} más',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cantidad en cajita gris
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (item.modifiers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: item.modifiers.map((m) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.orange.shade300,
                                              width: 0.8),
                                        ),
                                        child: Text(
                                          m,
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              if (item.notes != null)
                                _buildNoteText(item.notes!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Botón LISTO (Rosa Mexicano, full-width) ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdvance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                elevation: 0,
              ),
              child: const Text(
                'LISTO',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteText(String note) {
    final clean = note
        .replaceAll('[PARA COMER AQUÍ]', '')
        .replaceAll('[PARA LLEVAR]', '')
        .trim();
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.speaker_notes_outlined,
              size: 12, color: Colors.red.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              clean,
              style: TextStyle(
                color: Colors.red.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
