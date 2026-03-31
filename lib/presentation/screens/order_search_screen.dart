import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/api_service.dart';
import '../../providers/pos_provider.dart';
import 'refund_screen.dart';

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

      // Usar el endpoint correcto con todos los filtros
      final response = await ApiService.fetchOrders(
        restaurantId: widget.restaurantId,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        paymentStatus: _selectedPaymentStatus,
        orderType: _selectedOrderType,
        dateFrom: _startDate != null ? _startDate!.toIso8601String().split('T')[0] : null,
        dateTo: _endDate != null ? _endDate!.toIso8601String().split('T')[0] : null,
      );
      
      setState(() {
        _orders = List<dynamic>.from(response['data'] ?? []);
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

class _OrderDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final ScrollController scrollController;

  const _OrderDetailsSheet({
    required this.order,
    required this.scrollController,
  });

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  List<Map<String, dynamic>> _activityLogs = [];
  bool _loadingLogs = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityLogs();
  }

  Future<void> _fetchActivityLogs() async {
    try {
      final logs = await ApiService.fetchOrderActivityLog(widget.order['id']);
      if (mounted) {
        setState(() {
          _activityLogs = logs;
          _loadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLogs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.order['order_details'] as List<dynamic>? ??
        widget.order['details'] as List<dynamic>? ?? [];
    final total = double.tryParse(widget.order['total'].toString()) ?? 0;
    final paymentStatus = widget.order['payment_status'] ?? 'pending';
    final payments = widget.order['payments'] as List<dynamic>? ?? [];
    final status = widget.order['status'] ?? '';
    final waiter = widget.order['waiter'] as Map<String, dynamic>?;
    final cashRegister = widget.order['cash_register'] as Map<String, dynamic>?;

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
          // Encabezado con orden y estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Orden #${widget.order['order_number'] ?? widget.order['id']}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              _buildStatusChip(paymentStatus),
            ],
          ),
          const SizedBox(height: 8),
          // Info general
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                widget.order['created_at'] != null
                    ? _OrderSearchScreenState._formatDateTimeStatic(DateTime.parse(widget.order['created_at']))
                    : 'Sin fecha',
              ),
              if (widget.order['table'] != null)
                _buildInfoChip(Icons.table_bar, 'Mesa ${widget.order['table']['table_number'] ?? widget.order['table']['id']}'),
              _buildInfoChip(
                widget.order['table_id'] != null ? Icons.restaurant : Icons.shopping_bag,
                widget.order['table_id'] != null ? 'En Mesa' : 'Kiosko',
              ),
              if (waiter != null)
                _buildInfoChip(Icons.person, 'Mesero: ${waiter['name'] ?? 'N/A'}'),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                // ─── Info de atención ───────────────────────
                _buildServiceInfoSection(waiter, cashRegister),
                const Divider(height: 24),

                // ─── Items de la orden ──────────────────────
                const Text(
                  'Consumo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...details.map((item) => _buildDetailItem(item)),
                const Divider(height: 32),
                // Total
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
                // Pagos realizados
                if (payments.isNotEmpty) ...[
                  const Divider(height: 32),
                  const Text(
                    'Pagos Realizados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...payments.map((p) => _buildPaymentItem(p)),
                ],

                // ─── Timeline de actividad ──────────────────
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Historial de Actividad',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActivityTimeline(),

                const SizedBox(height: 24),
                // Acciones
                if (paymentStatus == 'paid' && status != 'voided') ...[
                  const Divider(height: 16),
                  const Text(
                    'Acciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Cerrar sheet
                        final posProvider = Provider.of<PosProvider>(context, listen: false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RefundScreen(
                              orderId: widget.order['id'],
                              orderTotal: total,
                              processedBy: posProvider.userId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.undo, color: Colors.orange),
                      label: const Text('Solicitar Reembolso'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                if (paymentStatus == 'pending') ...[
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Esta orden está pendiente de pago. Regresa a la pantalla de caja para procesarla.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sección de info de servicio ─────────────────────────
  Widget _buildServiceInfoSection(Map<String, dynamic>? waiter, Map<String, dynamic>? cashRegister) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Atención',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          _buildServiceRow(
            Icons.storefront,
            'Atendido en',
            widget.order['table_id'] != null ? 'Restaurante (Mesa)' : 'Kiosko',
          ),
          if (waiter != null) ...[
            const SizedBox(height: 6),
            _buildServiceRow(Icons.person, 'Mesero', waiter['name'] ?? 'N/A'),
          ],
          if (cashRegister != null) ...[
            const SizedBox(height: 6),
            _buildServiceRow(
              Icons.point_of_sale,
              'Caja',
              cashRegister['cash_register_number'] ?? 'Caja #${cashRegister['id']}',
            ),
          ],
          const SizedBox(height: 6),
          _buildServiceRow(
            Icons.access_time,
            'Hora de orden',
            widget.order['created_at'] != null
                ? _OrderSearchScreenState._formatDateTimeStatic(DateTime.parse(widget.order['created_at']))
                : 'Sin fecha',
          ),
          if (widget.order['status'] != null) ...[
            const SizedBox(height: 6),
            _buildServiceRow(Icons.flag, 'Estado', _formatStatus(widget.order['status'])),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─── Timeline de actividad ───────────────────────────────
  Widget _buildActivityTimeline() {
    if (_loadingLogs) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_activityLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 18),
            SizedBox(width: 8),
            Text('No hay registros de actividad aún', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: _activityLogs.asMap().entries.map((entry) {
        final index = entry.key;
        final log = entry.value;
        final isLast = index == _activityLogs.length - 1;
        return _buildTimelineItem(log, isLast);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> log, bool isLast) {
    final action = log['action'] ?? '';
    final description = log['description'] ?? '';
    final userName = log['user_name'] ?? 'Sistema';
    final userRole = log['user_role'] ?? '';
    final createdAt = log['created_at'] != null
        ? _OrderSearchScreenState._formatDateTimeStatic(DateTime.parse(log['created_at']))
        : '';
    final properties = log['properties'] as Map<String, dynamic>? ?? {};

    final actionInfo = _getActionInfo(action);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea del timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: actionInfo.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(actionInfo.icon, size: 14, color: Colors.white),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Contenido
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          actionInfo.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: actionInfo.color,
                          ),
                        ),
                      ),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '$userName${userRole.isNotEmpty ? ' ($userRole)' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  // Detalles extra según la acción
                  if (properties.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildPropertiesChips(action, properties),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesChips(String action, Map<String, dynamic> props) {
    final chips = <Widget>[];

    switch (action) {
      case 'order_created':
        if (props['source'] != null) {
          chips.add(_propChip('Origen: ${props['source']}', Icons.location_on));
        }
        if (props['waiter_name'] != null) {
          chips.add(_propChip('Mesero: ${props['waiter_name']}', Icons.person));
        }
        if (props['items_count'] != null) {
          chips.add(_propChip('${props['items_count']} items', Icons.list_alt));
        }
        break;
      case 'order_paid':
        if (props['cashier_name'] != null) {
          chips.add(_propChip('Cajero: ${props['cashier_name']}', Icons.person));
        }
        if (props['payment_method'] != null) {
          chips.add(_propChip('Método: ${props['payment_method']}', Icons.payment));
        }
        if (props['total_paid'] != null) {
          chips.add(_propChip('\$${double.tryParse(props['total_paid'].toString())?.toStringAsFixed(2) ?? props['total_paid']}', Icons.attach_money));
        }
        break;
      case 'order_voided':
        if (props['supervisor_name'] != null) {
          chips.add(_propChip('Supervisor: ${props['supervisor_name']}', Icons.admin_panel_settings));
        }
        if (props['reason'] != null) {
          chips.add(_propChip('Razón: ${props['reason']}', Icons.comment));
        }
        break;
      case 'order_items_added':
        if (props['items_added'] != null) {
          chips.add(_propChip('+${props['items_added']} items', Icons.add_circle));
        }
        if (props['added_by'] != null) {
          chips.add(_propChip('Por: ${props['added_by']}', Icons.person));
        }
        break;
      case 'order_item_courtesy':
        if (props['product_name'] != null) {
          chips.add(_propChip(props['product_name'], Icons.card_giftcard));
        }
        if (props['reason'] != null) {
          chips.add(_propChip('Razón: ${props['reason']}', Icons.comment));
        }
        break;
      case 'order_status_changed':
        if (props['old_status'] != null && props['new_status'] != null) {
          chips.add(_propChip('${_formatStatus(props['old_status'])} → ${_formatStatus(props['new_status'])}', Icons.swap_horiz));
        }
        break;
      case 'order_cancelled':
        if (props['cancelled_by'] != null) {
          chips.add(_propChip('Por: ${props['cancelled_by']}', Icons.person));
        }
        break;
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _propChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  _ActionInfo _getActionInfo(String action) {
    switch (action) {
      case 'order_created':
        return _ActionInfo('Orden Creada', Icons.add_circle, Colors.green);
      case 'order_status_changed':
        return _ActionInfo('Cambio de Estado', Icons.swap_horiz, Colors.blue);
      case 'order_paid':
        return _ActionInfo('Pago Procesado', Icons.payment, Colors.teal);
      case 'order_items_added':
        return _ActionInfo('Items Agregados', Icons.playlist_add, Colors.indigo);
      case 'order_cancelled':
        return _ActionInfo('Orden Cancelada', Icons.cancel, Colors.red);
      case 'order_voided':
        return _ActionInfo('Orden Anulada', Icons.block, Colors.red.shade800);
      case 'order_item_courtesy':
        return _ActionInfo('Cortesía', Icons.card_giftcard, Colors.purple);
      default:
        return _ActionInfo('Actividad', Icons.info, Colors.grey);
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'confirmed': return 'Confirmado';
      case 'preparing': return 'Preparando';
      case 'ready': return 'Listo';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      case 'voided': return 'Anulado';
      default: return status;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Pagado';
        break;
      case 'partial':
        color = Colors.orange;
        label = 'Parcial';
        break;
      default:
        color = Colors.red;
        label = 'Pendiente';
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }

  Widget _buildPaymentItem(dynamic payment) {
    final amount = double.tryParse(payment['amount'].toString()) ?? 0;
    final method = payment['payment_method']?['name'] ?? 'Método desconocido';
    final paymentStatus = payment['status'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            paymentStatus == 'completed' ? Icons.check_circle : Icons.pending,
            size: 18,
            color: paymentStatus == 'completed' ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(method)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 0;
    final product = item['product'] as Map<String, dynamic>?;
    final price = double.tryParse(
        (item['unit_price'] ?? item['price'] ?? product?['price'] ?? 0).toString()) ?? 0;
    final subtotal = double.tryParse(
        (item['subtotal'] ?? (quantity * price)).toString()) ?? (quantity * price);
    final productName = product?['name'] ?? item['product_name'] ?? 'Item';

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
                  productName,
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

class _ActionInfo {
  final String label;
  final IconData icon;
  final Color color;

  _ActionInfo(this.label, this.icon, this.color);
}
