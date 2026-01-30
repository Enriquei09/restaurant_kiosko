import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';

class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> {
  List<KitchenOrder> orders = [];
  bool isLoading = true;
  String? error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final restaurantId = await ConfigurationService.getRestaurantId();
      // Fetch ONLY 'ready' orders
      final response = await ApiService.fetchKitchenOrders(
        restaurantId: restaurantId,
        status: 'ready', 
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

  Future<void> _markAsDelivered(int orderId) async {
    try {
      await ApiService.updateOrderStatus(orderId: orderId, status: 'delivered');
      _loadOrders(); // Refresh immediately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden marcada como entregada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zona de Entrega (Runner)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
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
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No hay pedidos listos para entregar',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _RunnerOrderCard(
                          order: orders[index],
                          onDeliver: _markAsDelivered,
                        );
                      },
                    ),
    );
  }
}

class _RunnerOrderCard extends StatelessWidget {
  final KitchenOrder order;
  final Function(int) onDeliver;

  const _RunnerOrderCard({
    required this.order,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    final isTakeAway = order.isTakeAway;
    final color = isTakeAway ? Colors.orange.shade100 : Colors.blue.shade100;
    final icon = isTakeAway ? Icons.shopping_bag : Icons.restaurant;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 32, color: Colors.black87),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${order.id}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order.orderTypeLabel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (order.clientName != null)
                  Text(
                    order.clientName!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Items Summary
                 ...order.items.map((item) => Padding(
                   padding: const EdgeInsets.symmetric(vertical: 4),
                   child: Row(
                     children: [
                       Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       const SizedBox(width: 12),
                       Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 16))),
                     ],
                   ),
                 )),
                 
                 const SizedBox(height: 24),
                 SizedBox(
                   width: double.infinity,
                   height: 50,
                   child: ElevatedButton.icon(
                     onPressed: () => onDeliver(order.id),
                     icon: const Icon(Icons.check),
                     label: const Text('MARCAR COMO ENTREGADO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.teal,
                       foregroundColor: Colors.white,
                     ),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
