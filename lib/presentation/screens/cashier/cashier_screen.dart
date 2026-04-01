import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/providers/auth_provider.dart';
import '../cash_register_screen.dart';
import '../order_search_screen.dart';
import '../split_payment_screen.dart';
import '../refund_screen.dart';
import '../../widgets/discount_dialog.dart';
import '../pos/direct_sales_screen.dart';
import '../../../service/reverb_service.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> with SingleTickerProviderStateMixin {
  List<KitchenOrder> orders = [];
  bool isLoading = true;
  String? error;
  Timer? _pollTimer;
  int? _currentCashRegisterId;
  DateTime? _cashRegisterOpenedAt;
  late TabController _tabController;
  bool _showOldOrders = true; // Mostrar u ocultar órdenes antiguas
  ReverbService? _reverb;
  
  // Listas separadas por tipo
  List<KitchenOrder> get tableOrders => _filterOrders(orders.where((o) => o.tableNumber != null).toList());
  List<KitchenOrder> get kioskOrders => _filterOrders(orders.where((o) => o.tableNumber == null).toList());
  
  // Filtrar órdenes antiguas si está desactivado el switch
  List<KitchenOrder> _filterOrders(List<KitchenOrder> ordersList) {
    if (_showOldOrders) return ordersList;
    if (_cashRegisterOpenedAt == null) return ordersList;
    return ordersList.where((o) => o.createdAt.isAfter(_cashRegisterOpenedAt!)).toList();
  }
  
  // Verificar si una orden es antigua (creada antes del turno actual)
  bool _isOldOrder(KitchenOrder order) {
    if (_cashRegisterOpenedAt == null) return false;
    return order.createdAt.isBefore(_cashRegisterOpenedAt!);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentCashRegister();
    _loadOrders();
    _initWebSocket();
    // Polling cada 5 segundos para que sea rápido
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _reverb?.dispose();
    super.dispose();
  }

  /// Inicializar WebSocket para escuchar eventos en tiempo real
  Future<void> _initWebSocket() async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) return;

      final restaurantId = await ConfigurationService.getRestaurantId();

      _reverb = ReverbService(
        token: token,
        restaurantId: restaurantId,
        onConnected: () {
          if (mounted) debugPrint('[Cashier] WebSocket conectado');
        },
        onDisconnected: () {
          if (mounted) debugPrint('[Cashier] WebSocket desconectado');
        },
        onEvent: _handleReverbEvent,
        onError: (err) {
          debugPrint('[Cashier] WebSocket error: $err');
        },
      );

      await _reverb!.connect();
    } catch (e) {
      debugPrint('[Cashier] Error inicializando WebSocket: $e');
    }
  }

  /// Manejar eventos que llegan por WebSocket
  void _handleReverbEvent(String event, Map<String, dynamic> data) {
    if (!mounted) return;

    debugPrint('[Cashier] Evento recibido: $event');

    // Recargar órdenes si llega un evento importante
    if (event == 'OrderCreated' ||
        event == '.OrderCreated' ||
        event == 'OrderStatusChanged' ||
        event == '.OrderStatusChanged' ||
        event == 'OrderPaid' ||
        event == '.OrderPaid') {
      _loadOrders();
    }
  }

  Future<void> _loadCurrentCashRegister() async {
    try {
      final restaurantId = await ConfigurationService.getRestaurantId();
      final pos = context.read<PosProvider>();
      final response = await ApiService.getCurrentCashRegister(
        userId: pos.userId,
        restaurantId: restaurantId,
      );
      if (mounted && response['cash_register'] != null) {
        setState(() {
          _currentCashRegisterId = response['cash_register']['id'];
          // Guardar fecha de apertura para detectar órdenes antiguas
          final openedAtStr = response['cash_register']['opened_at'];
          if (openedAtStr != null) {
            _cashRegisterOpenedAt = DateTime.parse(openedAtStr);
          }
        });
      }
    } catch (e) {
      print('No hay caja abierta: $e');
    }
  }

  Future<void> _loadOrders() async {
    try {
      final restaurantId = await ConfigurationService.getRestaurantId();
      
      // Obtener órdenes pendientes de pago (incluye órdenes de mesa confirmadas)
      final response = await ApiService.fetchPendingPaymentOrders(restaurantId);

      if (mounted) {
        setState(() {
          // Convertir a KitchenOrder para mantener compatibilidad con la UI
          orders = response.map((orderData) {
            return KitchenOrder(
              id: orderData['id'],
              orderNumber: orderData['order_number'] ?? orderData['id'].toString().padLeft(4, '0'),
              tableNumber: orderData['table']?['name']?.toString(),
              status: orderData['status'] ?? 'pending',
              paymentStatus: orderData['payment_status'] ?? 'pending',
              total: double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0,
              tip: double.tryParse(orderData['tip']?.toString() ?? '0') ?? 0.0,
              items: (orderData['order_details'] as List?)?.map((item) {
                return KitchenOrderItem(
                  id: item['id'],
                  productName: item['product']?['name'] ?? item['product_name'] ?? 'Producto',
                  quantity: item['quantity'] ?? 1,
                  unitPrice: double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0,
                  notes: item['notes'],
                  modifiers: [],
                );
              }).toList() ?? [],
              createdAt: orderData['created_at'] != null 
                ? DateTime.parse(orderData['created_at'])
                : DateTime.now(),
            );
          }).toList();
          isLoading = false;
          error = null;
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

  Future<void> _confirmPayment(int orderId) async {
    if (_currentCashRegisterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes abrir una caja primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar si es una orden antigua y pedir confirmación
    final order = orders.firstWhere((o) => o.id == orderId);
    if (_isOldOrder(order)) {
      final confirmed = await _showOldOrderWarning(order);
      if (!confirmed) return;
    }

    try {
      await ApiService.payOrder(
        orderId: orderId,
        paymentMethod: 'cash',
        cashRegisterId: _currentCashRegisterId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Pago registrado! Mesa liberada.',
                style: TextStyle(fontFamily: 'Inter')),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadOrders(); // Recargar inmediatamente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      // Usar el endpoint DELETE /api/orders/{id} que sí permite cajeros
      await ApiService.cancelOrder(orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden cancelada')),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Constantes de diseño ──────────────────────────────────
  static const _kBg    = Color(0xFFF5F5F5);
  static const _kPink  = Color(0xFFE91E63);
  static const _kDark  = Color(0xFF212121);
  static const _kSub   = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final oldOrdersCount = orders.where(_isOldOrder).length;
    final activeCount = tableOrders.length;
    final kioskCount  = kioskOrders.length;

    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final userName = posProvider.currentCashRegister?.user?.name ?? 'Usuario';

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Reloj
                  Text(
                    _formatCurrentTime(),
                    style: const TextStyle(
                      color: _kDark,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Caja',
                    style: TextStyle(
                      color: _kSub,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  // ── SegmentedButton tabs ──
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'mesas',
                        label: Text(
                          activeCount > 0 ? 'Mesas ($activeCount)' : 'Mesas',
                          style: const TextStyle(fontFamily: 'Inter'),
                        ),
                        icon: const Icon(Icons.table_restaurant_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'kiosko',
                        label: Text(
                          kioskCount > 0 ? 'Kiosko ($kioskCount)' : 'Kiosko',
                          style: const TextStyle(fontFamily: 'Inter'),
                        ),
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                      ),
                    ],
                    selected: {_tabController.index == 0 ? 'mesas' : 'kiosko'},
                    onSelectionChanged: (sel) {
                      setState(() {
                        _tabController.index = sel.first == 'mesas' ? 0 : 1;
                      });
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((s) {
                        return s.contains(WidgetState.selected)
                            ? _kDark
                            : Colors.grey.shade100;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((s) {
                        return s.contains(WidgetState.selected)
                            ? Colors.white
                            : _kSub;
                      }),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      side: WidgetStateProperty.all(BorderSide.none),
                      textStyle: WidgetStateProperty.all(const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      )),
                    ),
                  ),
                  const Spacer(),
                  // ── Acciones rápidas ──
                  _headerAction(Icons.account_balance_wallet_outlined, 'Caja',
                      () => _navigateToCashRegister(context)),
                  const SizedBox(width: 6),
                  _headerAction(Icons.search_rounded, 'Buscar',
                      () => _navigateToOrderSearch(context)),
                  const SizedBox(width: 6),
                  _headerAction(Icons.refresh_rounded, 'Sync', () {
                    setState(() => isLoading = true);
                    _loadOrders();
                  }),
                  const SizedBox(width: 16),
                  // ── Avatar + menú ──
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        final auth = context.read<AuthProvider>();
                        await auth.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        }
                      }
                    },
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(userName,
                            style: TextStyle(
                                color: _kSub, fontWeight: FontWeight.w600)),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout_rounded, size: 20, color: _kPink),
                          SizedBox(width: 12),
                          Text('Salir'),
                        ]),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(userName,
                            style: TextStyle(
                                color: _kSub,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter')),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _kPink,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Banner órdenes antiguas ──
          if (oldOrdersCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$oldOrdersCount ${oldOrdersCount == 1 ? 'orden' : 'órdenes'} fuera del turno',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontFamily: 'Inter'),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showOldOrders = !_showOldOrders),
                    child: Text(
                      _showOldOrders ? 'Ocultar' : 'Mostrar',
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),

          // ── Body ──
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: _kPink))
                : error != null
                    ? Center(
                        child: Text('Error: $error',
                            style: const TextStyle(color: _kSub)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrdersList(
                            orders: tableOrders,
                            emptyIcon: Icons.table_restaurant_outlined,
                            emptyMessage:
                                'No hay órdenes de mesa pendientes',
                          ),
                          _buildOrdersList(
                            orders: kioskOrders,
                            emptyIcon: Icons.storefront_outlined,
                            emptyMessage:
                                'No hay órdenes de kiosko pendientes',
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DirectSalesScreen()),
          );
        },
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _headerAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _kSub),
        ),
      ),
    );
  }

  Widget _buildOrdersList({
    required List<KitchenOrder> orders,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                  fontSize: 16, color: _kSub, fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _CashierOrderCard(
          order: orders[index],
          isOldOrder: _isOldOrder(orders[index]),
          onConfirm: _confirmPayment,
          onCancel: _cancelOrder,
          onPaymentOptions: _showPaymentOptions,
          onDiscount: _showDiscountDialog,
          onRefund: _showRefundScreen,
        );
      },
    );
  }

  // Diálogo de advertencia para órdenes antiguas
  Future<bool> _showOldOrderWarning(KitchenOrder order) async {
    final timeAgo = DateTime.now().difference(order.createdAt);
    final hoursAgo = timeAgo.inHours;
    final daysAgo = timeAgo.inDays;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.history_rounded,
                  color: Colors.orange.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Orden Fuera de Turno',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta orden fue creada hace ${daysAgo > 0 ? '$daysAgo día(s)' : '$hoursAgo hora(s)'}, ANTES de abrir la caja actual.',
              style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${order.orderNumber}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  Text('Total: \$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                  Text('Creada: ${_formatFullDate(order.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF757575), fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'El pago se registrará en el turno actual.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                  fontFamily: 'Inter'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(
                    color: Color(0xFF757575), fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar Pago',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _navigateToCashRegister(BuildContext context) async {
    final restaurantId = await ConfigurationService.getRestaurantId();
    final pos = context.read<PosProvider>();
    final userId = pos.userId;
    final tenantId = pos.tenantId;
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashRegisterScreen(
            userId: userId,
            restaurantId: restaurantId,
            tenantId: tenantId,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToOrderSearch(BuildContext context) async {
    final restaurantId = await ConfigurationService.getRestaurantId();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSearchScreen(restaurantId: restaurantId),
        ),
      );
    }
  }

  void _showPaymentOptions(KitchenOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SplitPaymentScreen(
          orderId: order.id,
          orderTotal: order.total,
          cashRegisterId: context.read<PosProvider>().currentCashRegister?.id ?? 0,
          onPaymentComplete: () {
            setState(() {
              orders.removeWhere((o) => o.id == order.id);
            });
          },
        ),
      ),
    );
  }

  void _showDiscountDialog(KitchenOrder order) {
    showDiscountDialog(
      context: context,
      orderId: order.id,
      orderTotal: order.total,
      appliedBy: context.read<PosProvider>().userId,
      onApplied: () {
        _loadOrders();
      },
    );
  }

  void _showRefundScreen(KitchenOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefundScreen(
          orderId: order.id,
          orderTotal: order.total,
          processedBy: context.read<PosProvider>().userId,
        ),
      ),
    ).then((success) {
      if (success == true) {
        _loadOrders();
      }
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _CashierOrderCard extends StatelessWidget {
  final KitchenOrder order;
  final bool isOldOrder;
  final Function(int) onConfirm;
  final Function(int) onCancel;
  final Function(KitchenOrder) onPaymentOptions;
  final Function(KitchenOrder) onDiscount;
  final Function(KitchenOrder) onRefund;

  static const _kPink = Color(0xFFE91E63);
  static const _kDark = Color(0xFF212121);
  static const _kSub  = Color(0xFF757575);

  const _CashierOrderCard({
    required this.order,
    required this.isOldOrder,
    required this.onConfirm,
    required this.onCancel,
    required this.onPaymentOptions,
    required this.onDiscount,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTable = order.tableNumber != null;
    final Color accent = isOldOrder
        ? Colors.red.shade500
        : (isTable ? const Color(0xFF1976D2) : Colors.orange.shade600);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accent, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row superior: info + total ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono en caja tenue
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isOldOrder
                        ? Icons.history_rounded
                        : (isTable
                            ? Icons.table_restaurant_outlined
                            : Icons.storefront_outlined),
                    size: 22,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _kDark,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (isOldOrder) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'FUERA DE TURNO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red.shade600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (order.tableNumber != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Mesa ${order.tableNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1565C0),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildStatusBadge(order.status),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(order.createdAt),
                            style: const TextStyle(
                                fontSize: 12,
                                color: _kSub,
                                fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Total
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _kDark,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),

            // ── Items ──
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Inter'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kDark,
                              fontFamily: 'Inter'),
                        ),
                      ),
                      Text(
                        '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kDark,
                            fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 14),

            // ── Acciones secundarias (botones pastel) ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pastelBtn(
                  label: 'Descuento',
                  icon: Icons.percent_rounded,
                  bg: const Color(0xFFFFF3E0),
                  fg: Colors.orange.shade800,
                  onTap: () => onDiscount(order),
                ),
                _pastelBtn(
                  label: 'Devolución',
                  icon: Icons.undo_rounded,
                  bg: const Color(0xFFFFEBEE),
                  fg: Colors.red.shade700,
                  onTap: () => onRefund(order),
                ),
                _pastelBtn(
                  label: 'Pagos Múltiples',
                  icon: Icons.call_split_rounded,
                  bg: const Color(0xFFF3E5F5),
                  fg: Colors.purple.shade700,
                  onTap: () => onPaymentOptions(order),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Botones principales ──
            Row(
              children: [
                // Cancelar — pastel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFFFFF5F5),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter')),
                  ),
                ),
                const SizedBox(width: 14),
                // Cobrar — Rosa Mexicano llamativo
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => onConfirm(order.id),
                    icon: const Icon(Icons.payments_outlined, size: 20),
                    label: const Text('COBRAR',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
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

  Widget _pastelBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        fg = Colors.orange.shade800;
        label = 'Pendiente';
        break;
      case 'confirmed':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        label = 'Confirmada';
        break;
      case 'preparing':
        bg = const Color(0xFFF3E5F5);
        fg = Colors.purple.shade700;
        label = 'Preparando';
        break;
      case 'ready':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Lista';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = _kSub;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar Orden',
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter')),
        content: const Text(
            '¿Estás seguro de que deseas cancelar esta orden? Esta acción no se puede deshacer.',
            style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Volver',
                style: TextStyle(color: _kSub, fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel(order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFEBEE),
              foregroundColor: Colors.red.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sí, Cancelar',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}
