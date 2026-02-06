import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import '../cash_register_screen.dart';
import '../order_search_screen.dart';
import '../split_payment_screen.dart';
import '../refund_screen.dart';
import '../../widgets/discount_dialog.dart';

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
    // Polling cada 5 segundos para que sea rápido
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCashRegister() async {
    try {
      final restaurantId = await ConfigurationService.getRestaurantId();
      final response = await ApiService.getCurrentCashRegister(
        userId: 1, // TODO: obtener del contexto de autenticación
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
          const SnackBar(
            content: Text('¡Pago registrado! Mesa liberada.'),
            backgroundColor: Colors.green,
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
      // Implementar endpoint de cancelar o usar updateStatus('cancelled')
      await ApiService.updateOrderStatus(orderId: orderId, status: 'cancelled');
      
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

  @override
  Widget build(BuildContext context) {
    // Contar órdenes antiguas
    final oldOrdersCount = orders.where(_isOldOrder).length;
    
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final userName = posProvider.currentCashRegister?.user?.name ?? 'Usuario';
    final userRole = 'Cajero'; // TODO: Obtener del rol real del usuario
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _formatCurrentTime(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            const Text('Caja - Pagos Pendientes'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$userRole - $userName',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_restaurant),
                  const SizedBox(width: 8),
                  Text('Mesas (${tableOrders.length})'),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store),
                  const SizedBox(width: 8),
                  Text('Kiosko (${kioskOrders.length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Gestión de Caja',
            onPressed: () => _navigateToCashRegister(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar Órdenes',
            onPressed: () => _navigateToOrderSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadOrders();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de advertencia y filtro de órdenes antiguas
          if (oldOrdersCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hay $oldOrdersCount ${oldOrdersCount == 1 ? 'orden' : 'órdenes'} fuera del turno actual',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          'Creadas antes de abrir la caja',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showOldOrders ? 'Ocultar' : 'Mostrar',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                      ),
                      Switch(
                        value: _showOldOrders,
                        activeColor: Colors.orange.shade700,
                        onChanged: (value) {
                          setState(() => _showOldOrders = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Contenido con tabs
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error'))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Órdenes de Mesa
                          _buildOrdersList(
                            orders: tableOrders,
                            emptyIcon: Icons.table_restaurant,
                            emptyMessage: 'No hay órdenes de mesa pendientes',
                          ),
                          // Tab 2: Órdenes de Kiosko
                          _buildOrdersList(
                            orders: kioskOrders,
                            emptyIcon: Icons.store,
                            emptyMessage: 'No hay órdenes de kiosko pendientes',
                          ),
                        ],
                      ),
          ),
        ],
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
            Icon(emptyIcon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Text('⚠️ Orden Fuera de Turno')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta orden fue creada hace ${daysAgo > 0 ? '$daysAgo día(s)' : '$hoursAgo hora(s)'}, ANTES de abrir la caja actual.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Total: \$${order.total.toStringAsFixed(2)}'),
                  Text('Creada: ${_formatFullDate(order.createdAt)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ El pago se registrará en el turno actual, pero la orden es de un turno anterior.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '¿Deseas continuar con el pago?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMAR PAGO'),
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
    final userId = 1; // TODO: Obtener del contexto de autenticación
    final tenantId = 1; // TODO: Obtener del contexto de autenticación
    
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
          cashRegisterId: 1, // TODO: Obtener de la caja actual
          onPaymentComplete: () {
            _loadOrders();
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
      appliedBy: 1, // TODO: Obtener del usuario actual
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
          processedBy: 1, // TODO: Obtener del usuario actual
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
    // Determinar el color del borde y cabecera según el origen
    final bool isTableOrder = order.tableNumber != null;
    // Si es orden antigua, usar color rojo de advertencia
    final Color borderColor = isOldOrder 
        ? Colors.red.shade600 
        : (isTableOrder ? Colors.blue.shade600 : Colors.orange.shade600);
    final Color headerColor = isOldOrder
        ? Colors.red.shade50
        : (isTableOrder ? Colors.blue.shade50 : Colors.orange.shade50);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          // Header con color distintivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOldOrder ? Icons.warning_amber : (isTableOrder ? Icons.table_restaurant : Icons.store),
                  color: borderColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOldOrder)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '⚠️ ORDEN ANTIGUA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        isTableOrder ? 'ORDEN DE MESA' : 'ORDEN KIOSKO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Información de la orden
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orden #${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (order.tableNumber != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Mesa ${order.tableNumber}',
                                style: const TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStatusBadge(order.status),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(order.createdAt),
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
            // Lista resumida de items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            // Opciones adicionales
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  label: 'Descuento',
                  icon: Icons.percent,
                  color: Colors.orange,
                  onTap: () => onDiscount(order),
                ),
                _buildActionChip(
                  label: 'Devolución',
                  icon: Icons.undo,
                  color: Colors.red,
                  onTap: () => onRefund(order),
                ),
                _buildActionChip(
                  label: 'Pagos Múltiples',
                  icon: Icons.payment,
                  color: Colors.purple,
                  onTap: () => onPaymentOptions(order),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => onConfirm(order.id),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('COBRAR EFECTIVO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pendiente';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmada';
        icon = Icons.check_circle_outline;
        break;
      case 'preparing':
        color = Colors.purple;
        label = 'Preparando';
        icon = Icons.restaurant;
        break;
      case 'ready':
        color = Colors.green;
        label = 'Lista';
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Orden'),
        content: const Text('¿Estás seguro de que deseas cancelar esta orden? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel(order.id);
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
