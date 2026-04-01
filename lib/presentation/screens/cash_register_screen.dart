import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/cash_register_provider.dart';
import '../../providers/pos_provider.dart';
import '../../models/cash_register.dart';

class CashRegisterScreen extends StatefulWidget {
  final int userId;
  final int restaurantId;
  final int tenantId;

  const CashRegisterScreen({
    Key? key,
    required this.userId,
    required this.restaurantId,
    required this.tenantId,
  }) : super(key: key);

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  bool _isLoading = true;
  CashRegister? _currentRegister;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentRegister();
    });
  }

  Future<void> _loadCurrentRegister() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<CashRegisterProvider>(context, listen: false);
      await provider.loadCurrentRegister(
        userId: widget.userId,
        restaurantId: widget.restaurantId,
      );
      setState(() {
        _currentRegister = provider.currentRegister;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 48,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cargando información de caja...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentRegister == null) {
      return _buildOpenRegisterScreen();
    } else {
      return _buildActiveRegisterScreen();
    }
  }

  Widget _buildOpenRegisterScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abrir Caja', style: TextStyle(fontWeight: FontWeight.w600)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _OpenCashRegisterForm(
          userId: widget.userId,
          restaurantId: widget.restaurantId,
          tenantId: widget.tenantId,
          onSuccess: () => _loadCurrentRegister(),
        ),
      ),
    );
  }

  Widget _buildActiveRegisterScreen() {
    final now = DateTime.now();
    final openedAt = _currentRegister?.openedAt ?? now;
    final duration = now.difference(openedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.point_of_sale_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentRegister!.terminal?.name ?? 'CAJA REGISTRADORA',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentRegister!.terminal?.terminalNumber ?? 'Caja #${_currentRegister!.id.toString().padLeft(4, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_currentRegister!.user != null) ...{
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, color: Colors.white70, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            _currentRegister!.user!.name,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    },
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'ACTIVA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Abierta hace ${hours}h ${minutes}m',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Caja Activa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar',
                  onPressed: _loadCurrentRegister,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildRegisterSummary(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/pos/nueva-venta');
        },
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildRegisterSummary() {
    final register = _currentRegister!;
    final expectedBalance = register.expectedBalance ?? register.openingBalance;
    final difference = expectedBalance - register.openingBalance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN FINANCIERO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D47A1).withOpacity(0.05),
                        const Color(0xFF1976D2).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Saldo Inicial',
                          '\$${register.openingBalance.toStringAsFixed(2)}',
                          Icons.savings_rounded,
                          const Color(0xFF2E7D32),
                          'Al abrir caja',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Saldo Esperado',
                          '\$${expectedBalance.toStringAsFixed(2)}',
                          Icons.account_balance_wallet_rounded,
                          const Color(0xFF1565C0),
                          'Actual proyectado',
                        ),
                      ),
                    ],
                  ),
                ),
                if (difference != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: difference > 0 ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: difference > 0 ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            difference > 0 ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                difference > 0 ? 'Ingresos del Turno' : 'Balance',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${difference > 0 ? '+' : ''}\$${difference.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: difference > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ACCIONES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfessionalButton(
            onPressed: () => _showReportDialog(),
            icon: Icons.assessment_rounded,
            label: 'Ver Reporte de Turno',
            subtitle: 'Consultar movimientos y transacciones',
            gradientColors: const [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
            iconColor: const Color(0xFF1976D2),
          ),
          const SizedBox(height: 16),
          _buildProfessionalButton(
            onPressed: () => _showCloseDialog(),
            icon: Icons.lock_rounded,
            label: 'Cerrar Caja',
            subtitle: 'Finalizar turno y arqueo de caja',
            gradientColors: const [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE53935)],
            iconColor: const Color(0xFFD32F2F),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recuerda realizar el arqueo de caja al finalizar tu turno',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildProfessionalButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReportDialog() async {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(registerId: _currentRegister!.id),
    );
  }

  Future<void> _showCloseDialog() async {
    showDialog(
      context: context,
      builder: (context) => _CloseCashRegisterDialog(
        register: _currentRegister!,
        onSuccess: () {
          Navigator.of(context).pop();
          
          // Limpiar la caja del PosProvider
          final posProvider = Provider.of<PosProvider>(context, listen: false);
          posProvider.setCurrentCashRegister(null);
          
          // Después de cerrar, limpiar la sesión y volver al formulario de apertura
          setState(() {
            _currentRegister = null;
            _isLoading = false;
          });
        },
      ),
    );
  }
}

// ============================================================================
// FORMULARIO DE APERTURA DE CAJA
// ============================================================================

class _OpenCashRegisterForm extends StatefulWidget {
  final int userId;
  final int restaurantId;
  final int tenantId;
  final VoidCallback onSuccess;

  const _OpenCashRegisterForm({
    required this.userId,
    required this.restaurantId,
    required this.tenantId,
    required this.onSuccess,
  });

  @override
  State<_OpenCashRegisterForm> createState() => _OpenCashRegisterFormState();
}

class _OpenCashRegisterFormState extends State<_OpenCashRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _openingBalanceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Denominaciones
  final Map<String, TextEditingController> _denominations = {
    'bills_1000': TextEditingController(),
    'bills_500': TextEditingController(),
    'bills_200': TextEditingController(),
    'bills_100': TextEditingController(),
    'bills_50': TextEditingController(),
    'bills_20': TextEditingController(),
    'coins_10': TextEditingController(),
    'coins_5': TextEditingController(),
    'coins_2': TextEditingController(),
    'coins_1': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _updateTotalFromDenominations();
  }

  void _updateTotalFromDenominations() {
    double total = 0;
    total += (int.tryParse(_denominations['bills_1000']!.text) ?? 0) * 1000;
    total += (int.tryParse(_denominations['bills_500']!.text) ?? 0) * 500;
    total += (int.tryParse(_denominations['bills_200']!.text) ?? 0) * 200;
    total += (int.tryParse(_denominations['bills_100']!.text) ?? 0) * 100;
    total += (int.tryParse(_denominations['bills_50']!.text) ?? 0) * 50;
    total += (int.tryParse(_denominations['bills_20']!.text) ?? 0) * 20;
    total += (int.tryParse(_denominations['coins_10']!.text) ?? 0) * 10;
    total += (int.tryParse(_denominations['coins_5']!.text) ?? 0) * 5;
    total += (int.tryParse(_denominations['coins_2']!.text) ?? 0) * 2;
    total += (int.tryParse(_denominations['coins_1']!.text) ?? 0) * 1;

    setState(() {
      _openingBalanceController.text = total.toStringAsFixed(2);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<CashRegisterProvider>(context, listen: false);
      
      final denominationDetails = {
        'bills_1000': int.tryParse(_denominations['bills_1000']!.text) ?? 0,
        'bills_500': int.tryParse(_denominations['bills_500']!.text) ?? 0,
        'bills_200': int.tryParse(_denominations['bills_200']!.text) ?? 0,
        'bills_100': int.tryParse(_denominations['bills_100']!.text) ?? 0,
        'bills_50': int.tryParse(_denominations['bills_50']!.text) ?? 0,
        'bills_20': int.tryParse(_denominations['bills_20']!.text) ?? 0,
        'coins_10': int.tryParse(_denominations['coins_10']!.text) ?? 0,
        'coins_5': int.tryParse(_denominations['coins_5']!.text) ?? 0,
        'coins_2': int.tryParse(_denominations['coins_2']!.text) ?? 0,
        'coins_1': int.tryParse(_denominations['coins_1']!.text) ?? 0,
      };

      await provider.openRegister(
        tenantId: widget.tenantId,
        restaurantId: widget.restaurantId,
        userId: widget.userId,
        terminalId: Provider.of<PosProvider>(context, listen: false).selectedTerminal?.id ?? 0,
        openingBalance: double.parse(_openingBalanceController.text),
        openingNotes: _notesController.text.isEmpty ? null : _notesController.text,
        denominationDetails: denominationDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caja abierta exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Conteo de Billetes y Monedas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDenominationSection(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _openingBalanceController,
              decoration: const InputDecoration(
                labelText: 'Monto Total de Apertura',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                filled: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              readOnly: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isSubmitting ? 'Abriendo...' : 'Abrir Caja'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenominationSection() {
    return Column(
      children: [
        _buildDenominationGroup('Billetes', [
          _buildDenominationField('bills_1000', 1000),
          _buildDenominationField('bills_500', 500),
          _buildDenominationField('bills_200', 200),
          _buildDenominationField('bills_100', 100),
          _buildDenominationField('bills_50', 50),
          _buildDenominationField('bills_20', 20),
        ]),
        const SizedBox(height: 16),
        _buildDenominationGroup('Monedas', [
          _buildDenominationField('coins_10', 10),
          _buildDenominationField('coins_5', 5),
          _buildDenominationField('coins_2', 2),
          _buildDenominationField('coins_1', 1),
        ]),
      ],
    );
  }

  Widget _buildDenominationGroup(String title, List<Widget> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildDenominationField(String key, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('\$$value:', style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: TextFormField(
              controller: _denominations[key],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(8),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _updateTotalFromDenominations(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '= \$${((int.tryParse(_denominations[key]!.text) ?? 0) * value).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _openingBalanceController.dispose();
    _notesController.dispose();
    _denominations.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}

// ============================================================================
// DIÁLOGO DE CIERRE DE CAJA
// ============================================================================

class _CloseCashRegisterDialog extends StatefulWidget {
  final CashRegister register;
  final VoidCallback onSuccess;

  const _CloseCashRegisterDialog({
    required this.register,
    required this.onSuccess,
  });

  @override
  State<_CloseCashRegisterDialog> createState() => _CloseCashRegisterDialogState();
}

class _CloseCashRegisterDialogState extends State<_CloseCashRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _closingBalanceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, TextEditingController> _denominations = {
    'bills_1000': TextEditingController(text: '0'),
    'bills_500': TextEditingController(text: '0'),
    'bills_200': TextEditingController(text: '0'),
    'bills_100': TextEditingController(text: '0'),
    'bills_50': TextEditingController(text: '0'),
    'bills_20': TextEditingController(text: '0'),
    'coins_10': TextEditingController(text: '0'),
    'coins_5': TextEditingController(text: '0'),
    'coins_2': TextEditingController(text: '0'),
    'coins_1': TextEditingController(text: '0'),
  };

  void _updateTotalFromDenominations() {
    double total = 0;
    total += (int.tryParse(_denominations['bills_1000']!.text) ?? 0) * 1000;
    total += (int.tryParse(_denominations['bills_500']!.text) ?? 0) * 500;
    total += (int.tryParse(_denominations['bills_200']!.text) ?? 0) * 200;
    total += (int.tryParse(_denominations['bills_100']!.text) ?? 0) * 100;
    total += (int.tryParse(_denominations['bills_50']!.text) ?? 0) * 50;
    total += (int.tryParse(_denominations['bills_20']!.text) ?? 0) * 20;
    total += (int.tryParse(_denominations['coins_10']!.text) ?? 0) * 10;
    total += (int.tryParse(_denominations['coins_5']!.text) ?? 0) * 5;
    total += (int.tryParse(_denominations['coins_2']!.text) ?? 0) * 2;
    total += (int.tryParse(_denominations['coins_1']!.text) ?? 0) * 1;

    setState(() {
      _closingBalanceController.text = total.toStringAsFixed(2);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<CashRegisterProvider>(context, listen: false);
      
      final denominationDetails = {
        'bills_1000': int.tryParse(_denominations['bills_1000']!.text) ?? 0,
        'bills_500': int.tryParse(_denominations['bills_500']!.text) ?? 0,
        'bills_200': int.tryParse(_denominations['bills_200']!.text) ?? 0,
        'bills_100': int.tryParse(_denominations['bills_100']!.text) ?? 0,
        'bills_50': int.tryParse(_denominations['bills_50']!.text) ?? 0,
        'bills_20': int.tryParse(_denominations['bills_20']!.text) ?? 0,
        'coins_10': int.tryParse(_denominations['coins_10']!.text) ?? 0,
        'coins_5': int.tryParse(_denominations['coins_5']!.text) ?? 0,
        'coins_2': int.tryParse(_denominations['coins_2']!.text) ?? 0,
        'coins_1': int.tryParse(_denominations['coins_1']!.text) ?? 0,
      };

      await provider.closeRegister(
        closingBalance: double.parse(_closingBalanceController.text),
        closingNotes: _notesController.text.isEmpty ? null : _notesController.text,
        denominationDetails: denominationDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caja cerrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedBalance = widget.register.openingBalance +
        (widget.register.expectedBalance ?? 0) - widget.register.openingBalance;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cerrar Caja',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Apertura:',
                          '\$${widget.register.openingBalance.toStringAsFixed(2)}',
                        ),
                        _buildInfoRow(
                          'Ventas Aprox:',
                          '\$${((widget.register.expectedBalance ?? widget.register.openingBalance) - widget.register.openingBalance).toStringAsFixed(2)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Esperado:',
                          '\$${expectedBalance.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conteo Final',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDenominationSection(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _closingBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'Total Contado',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  readOnly: true,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas de cierre (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSubmitting ? 'Cerrando...' : 'Cerrar Caja'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 16 : 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 18 : 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationSection() {
    return Column(
      children: [
        ...['bills_1000', 'bills_500', 'bills_200', 'bills_100', 'bills_50', 'bills_20']
            .map((key) => _buildCompactDenominationField(
                  key,
                  int.parse(key.split('_')[1]),
                )),
        ...['coins_10', 'coins_5', 'coins_2', 'coins_1']
            .map((key) => _buildCompactDenominationField(
                  key,
                  int.parse(key.split('_')[1]),
                )),
      ],
    );
  }

  Widget _buildCompactDenominationField(String key, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text('\$$value:', style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: TextFormField(
              controller: _denominations[key],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _updateTotalFromDenominations(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '\$${((int.tryParse(_denominations[key]!.text) ?? 0) * value).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _closingBalanceController.dispose();
    _notesController.dispose();
    _denominations.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}

// ============================================================================
// DIÁLOGO DE REPORTE — THALO STYLE
// ============================================================================

class _ReportDialog extends StatefulWidget {
  final int registerId;

  const _ReportDialog({required this.registerId});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<CashRegisterProvider>(context, listen: false);
      final report = await provider.getReport(widget.registerId);
      setState(() {
        _report = report;
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

  // ── helpers ────────────────────────────────────────────────────────────────

  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: _buildAppBar(context),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1565C0),
                  strokeWidth: 3,
                ),
              )
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Color(0xFF1B1B1B)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Resumen del Turno',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1B1B),
            ),
          ),
          Text(
            'Corte de caja',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de impresión próximamente'),
                  backgroundColor: Color(0xFF1565C0),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text(
              'Imprimir Corte',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.2),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  // ── body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_report == null) {
      return const Center(
        child: Text('No hay datos disponibles',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final register = _report!['cash_register'] as Map<String, dynamic>?;
    final salesSummary = _report!['sales_summary'] as Map<String, dynamic>?;

    if (register == null) {
      return const Center(child: Text('No hay datos de caja'));
    }

    final user = register['user'] as Map<String, dynamic>?;
    final cashierName = user?['name'] ?? 'N/A';

    final double openingBalance = _toDouble(register['opening_balance']);
    final double totalSales = _toDouble(salesSummary?['total_sales']);
    final double cashSales = _toDouble(salesSummary?['cash_sales']);
    final double cardSales = _toDouble(salesSummary?['card_sales']);
    final double otherSales = _toDouble(salesSummary?['other_sales']);
    final double expectedBalance = _toDouble(register['expected_balance']);
    final double totalTips = _toDouble(salesSummary?['total_tips']);
    final int totalOrders =
        (salesSummary?['total_orders'] as num?)?.toInt() ?? 0;

    final cashEntries =
        (_report!['cash_entries'] as List<dynamic>?) ?? [];
    final cashExits =
        (_report!['cash_exits'] as List<dynamic>?) ?? [];
    final categorySales =
        (_report!['category_sales'] as List<dynamic>?) ?? [];

    final openedAt = register['opened_at'] != null
        ? DateTime.tryParse(register['opened_at'].toString())
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info del cajero ──────────────────────────────────────────────
          _buildInfoCard(cashierName, register, openedAt),
          const SizedBox(height: 22),

          // ── KPI chips ────────────────────────────────────────────────
          _buildSectionLabel('RESUMEN FINANCIERO'),
          const SizedBox(height: 12),
          _buildKpiRow(openingBalance, totalSales, expectedBalance, totalOrders, totalTips),
          const SizedBox(height: 22),

          // ── Pie + desglose ───────────────────────────────────────────────
          _buildSectionLabel('MÉTODOS DE PAGO  ·  DESGLOSE'),
          const SizedBox(height: 12),
          _buildDistributionRow(cashSales, cardSales, otherSales, salesSummary),
          const SizedBox(height: 22),

          // ── Ventas por categoría ─────────────────────────────────────────
          _buildSectionLabel('VENTAS POR CATEGORÍA'),
          const SizedBox(height: 12),
          _buildCategorySales(categorySales, totalSales),
          const SizedBox(height: 22),

          // ── Entradas de efectivo ─────────────────────────────────────────
          _buildSectionLabel('ENTRADAS DE EFECTIVO'),
          const SizedBox(height: 12),
          _buildMovementCard(cashEntries, isEntry: true),
          const SizedBox(height: 22),

          // ── Salidas de efectivo ──────────────────────────────────────────
          _buildSectionLabel('SALIDAS DE EFECTIVO'),
          const SizedBox(height: 12),
          _buildMovementCard(cashExits, isEntry: false),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF999999),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard(
    String cashierName,
    Map<String, dynamic> register,
    DateTime? openedAt,
  ) {
    final isOpen = (register['status'] ?? 'open') == 'open';

    String formattedDate = 'N/A';
    if (openedAt != null) {
      formattedDate =
          '${openedAt.day.toString().padLeft(2, '0')}/${openedAt.month.toString().padLeft(2, '0')}/${openedAt.year}  '
          '${openedAt.hour.toString().padLeft(2, '0')}:${openedAt.minute.toString().padLeft(2, '0')}';
    }

    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Color(0xFF1565C0),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cashierName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Apertura: $formattedDate',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Caja #${register['id']?.toString().padLeft(4, '0') ?? 'N/A'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOpen
                  ? const Color(0xFF00C853).withOpacity(0.12)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOpen ? 'ACTIVA' : 'CERRADA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isOpen
                    ? const Color(0xFF00C853)
                    : Colors.orange.shade700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI chips compactos en fila horizontal ─────────────────────────────

  Widget _buildKpiRow(
    double openingBalance,
    double totalSales,
    double expectedBalance,
    int totalOrders,
    double totalTips,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildKpiChip(
            label: 'Saldo Inicial',
            value: '\$${openingBalance.toStringAsFixed(2)}',
            icon: Icons.savings_rounded,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          _buildKpiChip(
            label: 'Total Ventas',
            value: '\$${totalSales.toStringAsFixed(2)}',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 10),
          _buildKpiChip(
            label: 'Saldo Esperado',
            value: '\$${expectedBalance.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(width: 10),
          _buildKpiChip(
            label: 'Órdenes',
            value: '$totalOrders',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFE91E63),
          ),
          if (totalTips > 0) ...[
            const SizedBox(width: 10),
            _buildKpiChip(
              label: 'Propinas',
              value: '\$${totalTips.toStringAsFixed(2)}',
              icon: Icons.volunteer_activism_rounded,
              color: const Color(0xFFFF6F00),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1B1B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Distribución 2 columnas: pie (izq) + desglose (der) ──────────────────

  Widget _buildDistributionRow(
    double cash,
    double card,
    double other,
    Map<String, dynamic>? salesSummary,
  ) {
    final total = cash + card + other;
    final isEmpty = total == 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Izquierda: Pie chart pequeño ─────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded,
                            size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 6),
                        Text('Sin ventas',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 11)),
                      ],
                    )
                  : SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: [
                                if (cash > 0)
                                  PieChartSectionData(
                                    value: cash,
                                    color: const Color(0xFF2E7D32),
                                    radius: 42,
                                    title:
                                        '${(cash / total * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (card > 0)
                                  PieChartSectionData(
                                    value: card,
                                    color: const Color(0xFF1565C0),
                                    radius: 42,
                                    title:
                                        '${(card / total * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (other > 0)
                                  PieChartSectionData(
                                    value: other,
                                    color: const Color(0xFFE91E63),
                                    radius: 42,
                                    title:
                                        '${(other / total * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B1B1B),
                                  height: 1.1,
                                ),
                              ),
                              const Text(
                                'total',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9CA3AF),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Derecha: lista de desglose ────────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBreakdownRow(
                    'Efectivo', '💵', cash, total,
                    const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    'Tarjeta', '💳', card, total,
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    'Otros', '📱', other, total,
                    const Color(0xFFE91E63),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String emoji,
    double amount,
    double total,
    Color color,
  ) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final isEmpty = amount == 0;
    final labelColor =
        isEmpty ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final valueColor =
        isEmpty ? const Color(0xFFD1D5DB) : const Color(0xFF1B1B1B);
    final barColor = isEmpty ? const Color(0xFFE5E7EB) : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 13,
                color: isEmpty ? const Color(0xFFD1D5DB) : null,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // ── Ventas por categoría ────────────────────────────────────────────────

  Widget _buildCategorySales(List<dynamic> categories, double totalSales) {
    // Paleta de colores cíclica para las barras
    const List<Color> _palette = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFE91E63),
      Color(0xFFFF6F00),
      Color(0xFF7B1FA2),
      Color(0xFF00838F),
      Color(0xFF558B2F),
      Color(0xFFC62828),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: categories.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.category_outlined,
                      size: 18, color: Colors.grey.shade300),
                  const SizedBox(width: 10),
                  Text('Sin datos de categorías',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < categories.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildCategoryRow(
                    name: (categories[i]['name'] ?? 'Sin categoría').toString(),
                    total: _toDouble(categories[i]['total']),
                    qty: (categories[i]['qty'] as num?)?.toInt() ?? 0,
                    grandTotal: totalSales,
                    color: _palette[i % _palette.length],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildCategoryRow({
    required String name,
    required double total,
    required int qty,
    required double grandTotal,
    required Color color,
  }) {
    final pct =
        grandTotal > 0 ? (total / grandTotal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$qty pzas',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1B1B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementCard(List<dynamic> movements, {required bool isEntry}) {
    final accentColor =
        isEntry ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final movementIcon = isEntry
        ? Icons.arrow_circle_down_rounded
        : Icons.arrow_circle_up_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: movements.isEmpty
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.grey.shade300, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isEntry
                        ? 'Sin entradas registradas'
                        : 'Sin salidas registradas',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade100,
                indent: 18,
                endIndent: 18,
              ),
              itemBuilder: (context, index) {
                final m = movements[index] as Map<String, dynamic>;
                final amount = _toDouble(m['amount']);
                final note = (m['notes'] ?? m['description'] ?? 'Sin descripción').toString();
                final createdAt = m['created_at'] != null
                    ? DateTime.tryParse(m['created_at'].toString())
                    : null;
                final time = createdAt != null
                    ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                    : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(movementIcon,
                            color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B1B1B),
                              ),
                            ),
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${isEntry ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ── Generic card shell ─────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: child,
    );
  }
}
