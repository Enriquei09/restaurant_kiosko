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
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Chips rápidos ──
  bool _filterToday = false;
  bool _filterYesterday = false;
  bool _filterCash = false;
  bool _filterCard = false;
  bool _filterPending = false;
  bool _filterPaid = false;
  
  @override
  void initState() {
    super.initState();
    _searchOrders();
  }

  Future<void> _searchOrders() async {
    setState(() => _isLoading = true);

    // ── Derivar fechas desde chips rápidos ──
    DateTime? effectiveStart = _startDate;
    DateTime? effectiveEnd = _endDate;
    if (_filterToday) {
      effectiveStart = DateTime.now();
      effectiveEnd = DateTime.now();
    } else if (_filterYesterday) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      effectiveStart = yesterday;
      effectiveEnd = yesterday;
    }

    // ── Estado de pago desde chips ──
    String? effectivePaymentStatus = _selectedPaymentStatus;
    if (_filterPending) effectivePaymentStatus = 'pending';
    if (_filterPaid) effectivePaymentStatus = 'paid';

    try {
      final response = await ApiService.fetchOrders(
        restaurantId: widget.restaurantId,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        paymentStatus: effectivePaymentStatus,
        orderType: _selectedOrderType,
        dateFrom: effectiveStart != null ? effectiveStart.toIso8601String().split('T')[0] : null,
        dateTo: effectiveEnd != null ? effectiveEnd.toIso8601String().split('T')[0] : null,
      );

      List<dynamic> results = List<dynamic>.from(response['data'] ?? []);

      // ── Filtro local de método de pago (chips Efectivo / Tarjeta) ──
      if (_filterCash || _filterCard) {
        results = results.where((order) {
          final payments = order['payments'] as List<dynamic>? ?? [];
          if (payments.isEmpty) return false;
          for (final p in payments) {
            final name = (p['payment_method']?['name'] ?? '').toString().toLowerCase();
            if (_filterCash &&
                (name.contains('efectivo') || name.contains('cash'))) return true;
            if (_filterCard &&
                (name.contains('tarjeta') || name.contains('card') ||
                 name.contains('visa') || name.contains('master'))) return true;
          }
          return false;
        }).toList();
      }

      setState(() {
        _orders = results;
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
      _startDate = null;
      _endDate = null;
      _filterToday = false;
      _filterYesterday = false;
      _filterCash = false;
      _filterCard = false;
      _filterPending = false;
      _filterPaid = false;
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
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Búsqueda de Órdenes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (!_isLoading)
              Text(
                '${_orders.length} resultado${_orders.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
    final hasActiveFilters = _filterToday || _filterYesterday || _filterCash ||
        _filterCard || _filterPending || _filterPaid ||
        _selectedOrderType != null || _startDate != null;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  'FILTROS RÁPIDOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade400,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                if (hasActiveFilters)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('Limpiar todo',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // ── Fecha ──
                _buildToggleChip(
                  label: 'Hoy',
                  icon: Icons.wb_sunny_outlined,
                  isActive: _filterToday,
                  activeColor: const Color(0xFF6200EA),
                  onTap: () {
                    setState(() {
                      _filterToday = !_filterToday;
                      if (_filterToday) {
                        _filterYesterday = false;
                        _startDate = null;
                        _endDate = null;
                      }
                    });
                    _searchOrders();
                  },
                ),
                const SizedBox(width: 8),
                _buildToggleChip(
                  label: 'Ayer',
                  icon: Icons.history_rounded,
                  isActive: _filterYesterday,
                  activeColor: const Color(0xFF6200EA),
                  onTap: () {
                    setState(() {
                      _filterYesterday = !_filterYesterday;
                      if (_filterYesterday) {
                        _filterToday = false;
                        _startDate = null;
                        _endDate = null;
                      }
                    });
                    _searchOrders();
                  },
                ),
                const SizedBox(width: 8),
                _buildToggleChip(
                  label: _startDate != null
                      ? '${_formatDate(_startDate!)}–${_formatDate(_endDate!)}'
                      : 'Rango',
                  icon: Icons.date_range_rounded,
                  isActive: _startDate != null,
                  activeColor: const Color(0xFF6200EA),
                  onTap: _selectDateRange,
                ),
                const SizedBox(width: 14),
                _buildSeparator(),
                const SizedBox(width: 14),
                // ── Método de pago ──
                _buildToggleChip(
                  label: 'Efectivo',
                  icon: Icons.payments_outlined,
                  isActive: _filterCash,
                  activeColor: const Color(0xFF2E7D32),
                  onTap: () {
                    setState(() {
                      _filterCash = !_filterCash;
                      if (_filterCash) _filterCard = false;
                    });
                    _searchOrders();
                  },
                ),
                const SizedBox(width: 8),
                _buildToggleChip(
                  label: 'Tarjeta',
                  icon: Icons.credit_card_rounded,
                  isActive: _filterCard,
                  activeColor: const Color(0xFF1565C0),
                  onTap: () {
                    setState(() {
                      _filterCard = !_filterCard;
                      if (_filterCard) _filterCash = false;
                    });
                    _searchOrders();
                  },
                ),
                const SizedBox(width: 14),
                _buildSeparator(),
                const SizedBox(width: 14),
                // ── Estado ──
                _buildToggleChip(
                  label: 'Pendiente',
                  icon: Icons.schedule_rounded,
                  isActive: _filterPending,
                  activeColor: Colors.orange.shade800,
                  onTap: () {
                    setState(() {
                      _filterPending = !_filterPending;
                      if (_filterPending) _filterPaid = false;
                    });
                    _searchOrders();
                  },
                ),
                const SizedBox(width: 8),
                _buildToggleChip(
                  label: 'Pagado',
                  icon: Icons.check_circle_outline_rounded,
                  isActive: _filterPaid,
                  activeColor: const Color(0xFF1B5E20),
                  onTap: () {
                    setState(() {
                      _filterPaid = !_filterPaid;
                      if (_filterPaid) _filterPending = false;
                    });
                    _searchOrders();
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.10) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: isActive ? activeColor : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey.shade700,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 5),
              Icon(Icons.close_rounded, size: 13, color: activeColor),
            ],
          ],
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
    return ColoredBox(
      color: const Color(0xFFF4F5F7),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // ── Helpers de método de pago ──
  IconData _getPaymentMethodIcon(String methodName) {
    final n = methodName.toLowerCase();
    if (n.contains('tarjeta') || n.contains('card') ||
        n.contains('visa') || n.contains('master')) return Icons.credit_card_rounded;
    if (n.contains('qr') || n.contains('transfer')) return Icons.qr_code_rounded;
    return Icons.payments_outlined; // efectivo
  }

  Color _getPaymentMethodColor(String methodName) {
    final n = methodName.toLowerCase();
    if (n.contains('tarjeta') || n.contains('card') ||
        n.contains('visa') || n.contains('master')) return const Color(0xFF1565C0);
    if (n.contains('qr') || n.contains('transfer')) return Colors.deepPurple;
    return const Color(0xFF2E7D32); // efectivo
  }

  String _getPrimaryPaymentMethod(Map<String, dynamic> order) {
    final payments = order['payments'] as List<dynamic>? ?? [];
    if (payments.isEmpty) return '';
    return payments.first['payment_method']?['name']?.toString() ?? '';
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final paymentStatus = order['payment_status'] ?? 'pending';
    final total = double.tryParse(order['total'].toString()) ?? 0;
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString();
    final primaryMethod = _getPrimaryPaymentMethod(order);
    final tableData = order['table'] as Map<String, dynamic>?;
    final tableName = tableData?['name']?.toString()
        ?? tableData?['table_number']?.toString();
    final createdAt = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'].toString())
        : null;

    // Color y etiqueta según estado
    final Color statusColor;
    final String statusLabel;
    switch (paymentStatus) {
      case 'paid':
        statusColor = const Color(0xFF2E7D32);
        statusLabel = 'Pagado';
        break;
      case 'partial':
        statusColor = Colors.orange.shade700;
        statusLabel = 'Parcial';
        break;
      default:
        statusColor = Colors.red.shade600;
        statusLabel = 'Pendiente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Franja de color por estado ──
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Fila 1: Número + badge estado ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$orderNumber',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  color: Color(0xFF1B1B1B),
                                ),
                              ),
                              if (createdAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    _formatDateTime(createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Badge de estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 12),

                    // ── Fila 2: Mesa / Kiosko + método de pago ──
                    Row(
                      children: [
                        if (tableName != null) ...[
                          Icon(Icons.table_bar_rounded,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 5),
                          Text(
                            'Mesa $tableName',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ] else ...[
                          Icon(Icons.storefront_outlined,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 5),
                          Text(
                            'Kiosko',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        if (primaryMethod.isNotEmpty) ...[
                          Icon(
                            _getPaymentMethodIcon(primaryMethod),
                            size: 14,
                            color: _getPaymentMethodColor(primaryMethod),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            primaryMethod,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getPaymentMethodColor(primaryMethod),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Fila 3: Monto destacado ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1565C0), // Azul Thalo
                          letterSpacing: -0.5,
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

  // ─── Sección de info de servicio ─────────────────────────

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
    final tableData = widget.order['table'] as Map<String, dynamic>?;
    final tableName = tableData?['name']?.toString()
        ?? tableData?['table_number']?.toString();
    final createdAt = widget.order['created_at'] != null
        ? _OrderSearchScreenState._formatDateTimeStatic(
            DateTime.parse(widget.order['created_at']))
        : 'Sin fecha';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Handle ──
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // ── Header con fondo gris tenue ──
        Container(
          color: const Color(0xFFF7F8FA),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '#${widget.order['order_number'] ?? widget.order['id']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B1B1B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusCapsule(paymentStatus),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14, runSpacing: 6,
                children: [
                  _buildMetaChip(Icons.calendar_today_outlined, createdAt),
                  if (tableName != null)
                    _buildMetaChip(Icons.table_bar_rounded, 'Mesa $tableName'),
                  if (tableName == null)
                    _buildMetaChip(Icons.storefront_outlined, 'Kiosko'),
                  if (waiter != null)
                    _buildMetaChip(Icons.person_outline_rounded,
                        waiter['name'] ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // ── Cuerpo ──
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            children: [
              // ── INFORMACIÓN ──
              _buildSectionLabel('INFORMACIÓN'),
              const SizedBox(height: 10),
              _buildServiceInfoSection(waiter, cashRegister),
              const SizedBox(height: 26),

              // ── CONSUMO ──
              _buildSectionLabel('CONSUMO'),
              const SizedBox(height: 10),
              ...details.map((item) =>
                  _buildDetailItem(item as Map<String, dynamic>)),
              const SizedBox(height: 8),
              // Fila de total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ),
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...payments.map((p) => _buildPaymentItem(p)),
              ],
              const SizedBox(height: 26),

              // ── HISTORIAL ──
              _buildSectionLabel('HISTORIAL'),
              const SizedBox(height: 14),
              _buildActivityTimeline(),
              const SizedBox(height: 24),

              // ── Acciones ──
              if (paymentStatus == 'paid' && status != 'voided') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final posProvider = Provider.of<PosProvider>(
                          context, listen: false);
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
                    icon: const Icon(Icons.undo_rounded, size: 17),
                    label: const Text('Solicitar Reembolso'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(
                          color: Colors.orange.shade300, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              if (paymentStatus == 'pending') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Esta orden está pendiente de pago. Regresa a la pantalla de caja para procesarla.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade400,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStatusCapsule(String status) {
    final Color bg;
    final String label;
    switch (status) {
      case 'paid':
        bg = const Color(0xFF00C853);
        label = 'Pagado';
        break;
      case 'partial':
        bg = Colors.orange.shade600;
        label = 'Parcial';
        break;
      default:
        bg = Colors.red.shade500;
        label = 'Pendiente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildServiceInfoSection(
      Map<String, dynamic>? waiter, Map<String, dynamic>? cashRegister) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.storefront_outlined,
            'Canal',
            widget.order['table_id'] != null ? 'Restaurante (Mesa)' : 'Kiosko',
          ),
          if (waiter != null) ...[
            Divider(height: 16, color: Colors.grey.shade200),
            _buildInfoRow(
                Icons.person_outline_rounded, 'Mesero', waiter['name'] ?? 'N/A'),
          ],
          if (cashRegister != null) ...[
            Divider(height: 16, color: Colors.grey.shade200),
            _buildInfoRow(
              Icons.point_of_sale_rounded,
              'Caja',
              cashRegister['cash_register_number'] ??
                  'Caja #${cashRegister['id']}',
            ),
          ],
          Divider(height: 16, color: Colors.grey.shade200),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Hora',
            widget.order['created_at'] != null
                ? _OrderSearchScreenState._formatDateTimeStatic(
                    DateTime.parse(widget.order['created_at']))
                : 'Sin fecha',
          ),
          if (widget.order['status'] != null) ...[
            Divider(height: 16, color: Colors.grey.shade200),
            _buildInfoRow(Icons.flag_outlined, 'Estado cocina',
                _formatStatus(widget.order['status'])),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
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
        ? _OrderSearchScreenState._formatDateTimeStatic(
            DateTime.parse(log['created_at']))
        : '';
    final properties = log['properties'] as Map<String, dynamic>? ?? {};
    final actionInfo = _getActionInfo(action);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nodo + línea ──
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: actionInfo.color.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: actionInfo.color.withOpacity(0.55), width: 1.5),
                  ),
                  child: Icon(actionInfo.icon,
                      size: 11, color: actionInfo.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                          width: 1, color: Colors.grey.shade200),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Card de contenido ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                      color: actionInfo.color.withOpacity(0.5), width: 2.5),
                  top: BorderSide(color: Colors.grey.shade100),
                  right: BorderSide(color: Colors.grey.shade100),
                  bottom: BorderSide(color: Colors.grey.shade100),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        actionInfo.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: actionInfo.color,
                        ),
                      ),
                      Text(
                        createdAt,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        '$userName${userRole.isNotEmpty ? ' · $userRole' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildPaymentItem(dynamic payment) {
    final amount = double.tryParse(payment['amount'].toString()) ?? 0;
    final method =
        payment['payment_method']?['name'] ?? 'Método desconocido';
    final pStatus = payment['status'] ?? '';
    final isPaid = pStatus == 'completed' || pStatus == 'paid';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isPaid
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            size: 15,
            color: isPaid
                ? const Color(0xFF00C853)
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(method,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Spacer(),
          Text('\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 0;
    final product = item['product'] as Map<String, dynamic>?;
    final price = double.tryParse(
            (item['unit_price'] ??
                    item['price'] ??
                    product?['price'] ??
                    0)
                .toString()) ??
        0;
    final subtotal = double.tryParse(
            (item['subtotal'] ?? (quantity * price)).toString()) ??
        (quantity * price);
    final productName =
        product?['name'] ?? item['product_name'] ?? 'Item';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text('$quantity',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('\$${price.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('\$${subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1B))),
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
