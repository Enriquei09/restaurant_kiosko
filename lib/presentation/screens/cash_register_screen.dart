import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
// DIÁLOGO DE REPORTE
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: const Text('Reporte de Turno'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildReportContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_report == null) return const Center(child: Text('No hay datos'));

    final data = _report!['data'] as Map<String, dynamic>;
    final register = data['register'] as Map<String, dynamic>;
    final payments = data['payments_by_method'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Información General', [
            _buildDataRow('Caja', '#${register['id']}'),
            _buildDataRow('Cajero', register['cashier']['name']),
            _buildDataRow('Apertura', register['opened_at'] ?? 'N/A'),
            _buildDataRow('Estado', register['status']),
          ]),
          const Divider(height: 32),
          _buildSection('Resumen Financiero', [
            _buildDataRow('Monto Inicial', '\$${register['opening_balance']}'),
            _buildDataRow('Ventas Totales', '\$${data['total_sales']}'),
            _buildDataRow('Total Órdenes', '${data['total_orders']}'),
            _buildDataRow('Monto Esperado', '\$${register['expected_balance'] ?? 'N/A'}'),
          ]),
          const Divider(height: 32),
          _buildSection('Pagos por Método', [
            ...payments.entries.map((e) => _buildDataRow(
                  e.key,
                  '\$${e.value}',
                )),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
