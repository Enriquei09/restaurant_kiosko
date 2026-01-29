import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<KitchenOrder> orders = [];
  Map<String, int> counts = {};
  bool isLoading = true;
  String? error;
  Timer? _pollTimer;
  String? lastSyncTime;
  String selectedTab = 'all'; // all, pending, preparing, ready

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Polling cada 10 segundos
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      // Filtrar según tab seleccionado
      String statusFilter = 'confirmed,preparing,ready'; // Por defecto, solo activas
      
      if (selectedTab == 'confirmed') {
        statusFilter = 'confirmed';
      } else if (selectedTab == 'preparing') {
        statusFilter = 'preparing';
      } else if (selectedTab == 'ready') {
        statusFilter = 'ready';
      }

      final restaurantId = await ConfigurationService.getRestaurantId();
      
      final response = await ApiService.fetchKitchenOrders(
        restaurantId: restaurantId,
        status: statusFilter,
      );

      setState(() {
        orders = response.orders;
        counts = response.counts;
        lastSyncTime = response.serverTime;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId: orderId, status: newStatus);
      _loadOrders(); // Recargar lista
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado')),
        );
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
        title: const Text('Cocina - Pedidos'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Actualizar',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Tabs de filtro
          Container(
            color: Colors.grey.shade200,
            child: Row(
              children: [
                _buildTabButton('Todos', 'all', (counts['confirmed'] ?? 0) + (counts['preparing'] ?? 0) + (counts['ready'] ?? 0)),
                _buildTabButton('Por Preparar', 'confirmed', counts['confirmed'] ?? 0),
                _buildTabButton('Preparando', 'preparing', counts['preparing'] ?? 0),
                _buildTabButton('Listos', 'ready', counts['ready'] ?? 0),
              ],
            ),
          ),

          // Lista de órdenes
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error'))
                    : orders.isEmpty
                        ? const Center(child: Text('No hay pedidos'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return _OrderCard(
                                order: orders[index],
                                onStatusChange: _updateStatus,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value, int count) {
    final isSelected = selectedTab == value;
    return Expanded(
      child: Material(
        color: isSelected ? Colors.orange : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedTab = value;
              isLoading = true;
            });
            _loadOrders();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final KitchenOrder order;
  final Function(int, String) onStatusChange;

  const _OrderCard({
    required this.order,
    required this.onStatusChange,
  });

  Color _getStatusColor() {
    switch (order.status) {
      case 'confirmed':
        return Colors.red.shade100;
      case 'preparing':
        return Colors.blue.shade100;
      case 'ready':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: _getStatusColor(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Orden #${order.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Cliente
            if (order.clientName != null)
              Text(
                '👤 ${order.clientName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const Divider(height: 16),

            // Items
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        if (item.modifiers.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 38),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: item.modifiers
                                  .map((mod) => Chip(
                                        label: Text(
                                          mod,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.orange.shade50,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                        if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 38),
                            child: Row(
                              children: [
                                const Icon(Icons.note, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.notes!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botones de acción
            const Divider(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Color _getStatusBadgeColor() {
    switch (order.status) {
      case 'confirmed':
        return Colors.red;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (order.status) {
      case 'confirmed':
        return ElevatedButton.icon(
          onPressed: () => onStatusChange(order.id, 'preparing'),
          icon: const Icon(Icons.restaurant),
          label: const Text('Iniciar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size.fromHeight(40),
          ),
        );
      case 'preparing':
        return ElevatedButton.icon(
          onPressed: () => onStatusChange(order.id, 'ready'),
          icon: const Icon(Icons.check_circle),
          label: const Text('Marcar Listo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(40),
          ),
        );
      case 'ready':
        return ElevatedButton.icon(
          onPressed: () => onStatusChange(order.id, 'delivered'),
          icon: const Icon(Icons.delivery_dining),
          label: const Text('Entregado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size.fromHeight(40),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
