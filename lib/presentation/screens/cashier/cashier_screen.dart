import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  List<KitchenOrder> orders = [];
  bool isLoading = true;
  String? error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Polling cada 5 segundos para que sea rápido
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final restaurantId = await ConfigurationService.getRestaurantId();
      
      // Usamos el endpoint de cocina pero filtramos solo pendientes
      // Nota: KitchenController ahora soporta 'pending' si lo pedimos explícitamente
      final response = await ApiService.fetchKitchenOrders(
        restaurantId: restaurantId,
        status: 'pending',
      );

      if (mounted) {
        setState(() {
          orders = response.orders;
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
    try {
      await ApiService.updateOrderStatus(orderId: orderId, status: 'confirmed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pago confirmado! Orden enviada a cocina.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja - Pagos Pendientes'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadOrders();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.point_of_sale, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No hay órdenes pendientes de pago',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _CashierOrderCard(
                          order: orders[index],
                          onConfirm: _confirmPayment,
                          onCancel: _cancelOrder,
                        );
                      },
                    ),
    );
  }
}

class _CashierOrderCard extends StatelessWidget {
  final KitchenOrder order;
  final Function(int) onConfirm;
  final Function(int) onCancel;

  const _CashierOrderCard({
    required this.order,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orden #${order.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.clientName != null)
                      Text(
                        order.clientName!,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                  ],
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
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
            const SizedBox(height: 24),
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
                    label: const Text('COBRAR Y CONFIRMAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
