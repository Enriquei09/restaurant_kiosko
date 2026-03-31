import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/api_service.dart';
import '../widgets/supervisor_auth_dialog.dart';

class RefundScreen extends StatefulWidget {
  final int orderId;
  final double orderTotal;
  final int processedBy;

  const RefundScreen({
    Key? key,
    required this.orderId,
    required this.orderTotal,
    required this.processedBy,
  }) : super(key: key);

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  
  bool _isFullRefund = true;
  String _refundMethod = 'cash';
  bool _isProcessing = false;
  int? _selectedDetailId;

  final List<RefundMethod> _refundMethods = [
    RefundMethod('cash', 'Efectivo', Icons.money, Colors.green),
    RefundMethod('card', 'Tarjeta', Icons.credit_card, Colors.blue),
    RefundMethod('transfer', 'Transferencia', Icons.account_balance, Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.orderTotal.toStringAsFixed(2);
  }

  void _onRefundTypeChanged(bool isFullRefund) {
    setState(() {
      _isFullRefund = isFullRefund;
      if (isFullRefund) {
        _selectedDetailId = null;
        _amountController.text = widget.orderTotal.toStringAsFixed(2);
      } else {
        _amountController.clear();
      }
    });
  }

  Future<void> _handleRefund() async {
    if (!_formKey.currentState!.validate()) return;

    // Solicitar autorización de supervisor
    final supervisor = await showSupervisorAuthDialog(
      context: context,
      title: 'Autorizar Devolución',
      description: 'Se requiere autorización para procesar esta devolución',
    );

    if (supervisor == null) return; // Usuario canceló

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      
      // Crear devolución
      final response = await ApiService.createRefund(
        orderId: widget.orderId,
        orderDetailId: _isFullRefund ? null : _selectedDetailId,
        amount: amount,
        reason: _reasonController.text,
        processedBy: widget.processedBy,
        refundMethod: _refundMethod,
      );

      if (response['success'] == true && mounted) {
        final refundId = response['data']['id'];
        
        // Autorizar automáticamente
        await ApiService.authorizeRefund(
          refundId: refundId,
          supervisorId: supervisor.id,
          supervisorPin: supervisor.pin,
        );
        
        // Completar devolución
        await ApiService.completeRefund(refundId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devolución procesada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true); // Retornar true indicando éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesar Devolución'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOrderInfo(),
              const SizedBox(height: 24),
              _buildRefundTypeSection(),
              const SizedBox(height: 20),
              _buildAmountSection(),
              const SizedBox(height: 20),
              _buildRefundMethodSection(),
              const SizedBox(height: 20),
              _buildReasonSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Información de la Orden',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.receipt_long, color: Colors.red.shade700),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orden #:', style: TextStyle(fontSize: 14)),
                Text(
                  '${widget.orderId}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total de la Orden:', style: TextStyle(fontSize: 14)),
                Text(
                  '\$${widget.orderTotal.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildRefundTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Devolución',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRefundTypeCard(
                title: 'Devolución Total',
                subtitle: 'Reembolsar orden completa',
                icon: Icons.replay,
                isSelected: _isFullRefund,
                onTap: () => _onRefundTypeChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRefundTypeCard(
                title: 'Devolución Parcial',
                subtitle: 'Reembolsar items específicos',
                icon: Icons.splitscreen,
                isSelected: !_isFullRefund,
                onTap: () => _onRefundTypeChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.red : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.red.shade700 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monto a Devolver',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            helperText: _isFullRefund
                ? 'Devolución total de la orden'
                : 'Ingrese el monto parcial a devolver',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          readOnly: _isFullRefund,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el monto';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Monto inválido';
            }
            if (amount > widget.orderTotal) {
              return 'El monto no puede ser mayor al total de la orden';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRefundMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Reembolso',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _refundMethods.map((method) {
            final isSelected = _refundMethod == method.id;
            return InkWell(
              onTap: () => setState(() => _refundMethod = method.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? method.color.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? method.color : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      method.icon,
                      color: isSelected ? method.color : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? method.color : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Razón de la Devolución',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Describa la razón',
            border: OutlineInputBorder(),
            hintText: 'Ej: Cliente insatisfecho con el producto...',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingrese la razón de la devolución';
            }
            if (value.trim().length < 10) {
              return 'La razón debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _handleRefund,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isProcessing ? 'Procesando...' : 'Procesar Devolución'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

// ============================================================================
// MODELO
// ============================================================================

class RefundMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  RefundMethod(this.id, this.name, this.icon, this.color);
}
