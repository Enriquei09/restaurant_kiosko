import 'package:flutter/material.dart';
import '../../service/api_service.dart';

class OrderSearchScreen extends StatefulWidget {
  final int restaurantId;

  const OrderSearchScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<OrderSearchScreen> createState() => _OrderSearchScreenState();
}

class _OrderSearchScreenState extends State<OrderSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _orders = [];
  
  // Filtros
  String? _selectedPaymentStatus;
  String? _selectedOrderType;
  int? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _paymentStatuses = ['pending', 'partial', 'paid'];
  final List<String> _orderTypes = ['dine_in', 'takeaway', 'delivery'];
  
  @override
  void initState() {
    super.initState();
    _searchOrders();
  }

  Future<void> _searchOrders() async {
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, dynamic>{
        'restaurant_id': widget.restaurantId,
      };

      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      if (_selectedPaymentStatus != null) {
        queryParams['payment_status'] = _selectedPaymentStatus;
      }
      if (_selectedOrderType != null) {
        queryParams['order_type'] = _selectedOrderType;
      }
      if (_selectedPaymentMethod != null) {
        queryParams['payment_method'] = _selectedPaymentMethod;
      }
      if (_startDate != null) {
        queryParams['start_date'] = _startDate!.toIso8601String().split('T')[0];
      }
      if (_endDate != null) {
        queryParams['end_date'] = _endDate!.toIso8601String().split('T')[0];
      }

      // Por ahora usamos fetchKitchenOrders que es el disponible
      final response = await ApiService.fetchKitchenOrders(
        restaurantId: widget.restaurantId,
      );
      
      setState(() {
        _orders = response.orders.map((o) => {
          'id': o.id,
          'total': o.total,
          'payment_status': 'pending',
          'order_type': 'dine_in',
          'table_number': o.tableName,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedPaymentStatus = null;
      _selectedOrderType = null;
      _selectedPaymentMethod = null;
      _startDate = null;
      _endDate = null;
    });
    _searchOrders();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _searchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Órdenes'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _searchOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFiltersSection(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por orden #, mesa, cliente...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchOrders();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onSubmitted: (_) => _searchOrders(),
      ),
    );
  }

  Widget _buildFiltersSection() {
    final hasActiveFilters = _selectedPaymentStatus != null ||
        _selectedOrderType != null ||
        _selectedPaymentMethod != null ||
        _startDate != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Rango de Fechas',
                  icon: Icons.date_range,
                  isActive: _startDate != null,
                  onTap: _selectDateRange,
                  value: _startDate != null
                      ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                      : null,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown<String>(
                  label: 'Estado de Pago',
                  value: _selectedPaymentStatus,
                  items: _paymentStatuses,
                  onChanged: (value) {
                    setState(() => _selectedPaymentStatus = value);
                    _searchOrders();
                  },
                  itemBuilder: (status) => _formatPaymentStatus(status),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown<String>(
                  label: 'Tipo de Orden',
                  value: _selectedOrderType,
                  items: _orderTypes,
                  onChanged: (value) {
                    setState(() => _selectedOrderType = value);
                    _searchOrders();
                  },
                  itemBuilder: (type) => _formatOrderType(type),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? value,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.blue : Colors.grey),
            const SizedBox(width: 6),
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.blue : Colors.grey.shade700,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: value != null ? Colors.blue.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != null ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          isDense: true,
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('Todos', style: const TextStyle(fontSize: 14)),
            ),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemBuilder(item),
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No se encontraron órdenes',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final paymentStatus = order['payment_status'] ?? 'pending';
    final orderType = order['order_type'] ?? 'dine_in';
    final total = double.tryParse(order['total'].toString()) ?? 0;
    
    Color statusColor;
    switch (paymentStatus) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'partial':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Orden #${order['id']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      _formatPaymentStatus(paymentStatus),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(_getOrderTypeIcon(orderType), size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatOrderType(orderType),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (order['table_number'] != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.table_bar, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Mesa ${order['table_number']}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['created_at'] != null
                        ? _formatDateTime(DateTime.parse(order['created_at']))
                        : 'Sin fecha',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _OrderDetailsSheet(
          order: order,
          scrollController: scrollController,
        ),
      ),
    );
  }

  String _formatPaymentStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'partial':
        return 'Parcial';
      case 'paid':
        return 'Pagado';
      default:
        return status;
    }
  }

  String _formatOrderType(String type) {
    switch (type) {
      case 'dine_in':
        return 'En Mesa';
      case 'takeaway':
        return 'Para Llevar';
      case 'delivery':
        return 'Domicilio';
      default:
        return type;
    }
  }

  IconData _getOrderTypeIcon(String type) {
    switch (type) {
      case 'dine_in':
        return Icons.restaurant;
      case 'takeaway':
        return Icons.shopping_bag;
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.shopping_cart;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDateTimeStatic(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// HOJA DE DETALLES DE ORDEN
// ============================================================================

class _OrderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final ScrollController scrollController;

  const _OrderDetailsSheet({
    required this.order,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final details = order['details'] as List<dynamic>? ?? [];
    final total = double.tryParse(order['total'].toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Orden #${order['id']}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            order['created_at'] != null
                ? _OrderSearchScreenState._formatDateTimeStatic(DateTime.parse(order['created_at']))
                : 'Sin fecha',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...details.map((item) => _buildDetailItem(item)).toList(),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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

  Widget _buildDetailItem(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 0;
    final price = double.tryParse(item['price'].toString()) ?? 0;
    final subtotal = quantity * price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(2)} c/u',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '\$${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
