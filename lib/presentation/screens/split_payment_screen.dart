import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/api_service.dart';

class SplitPaymentScreen extends StatefulWidget {
  final int orderId;
  final double orderTotal;
  final int cashRegisterId;
  final Function() onPaymentComplete;

  const SplitPaymentScreen({
    Key? key,
    required this.orderId,
    required this.orderTotal,
    required this.cashRegisterId,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends State<SplitPaymentScreen> {
  final List<PaymentEntry> _payments = [];
  bool _isProcessing = false;
  
  // Métodos de pago disponibles (en producción, cargar desde API)
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(id: 1, name: 'Efectivo', icon: Icons.money, color: Colors.green),
    PaymentMethod(id: 2, name: 'Tarjeta Débito', icon: Icons.credit_card, color: Colors.blue),
    PaymentMethod(id: 3, name: 'Tarjeta Crédito', icon: Icons.credit_card, color: Colors.orange),
    PaymentMethod(id: 4, name: 'Transferencia', icon: Icons.account_balance, color: Colors.purple),
    PaymentMethod(id: 5, name: 'Digital (App)', icon: Icons.phone_android, color: Colors.teal),
  ];

  double get _totalPaid {
    return _payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  double get _remaining {
    return widget.orderTotal - _totalPaid;
  }

  bool get _isComplete {
    return _remaining <= 0;
  }

  void _addPayment(PaymentMethod method) {
    final amountController = TextEditingController(
      text: _remaining > 0 ? _remaining.toStringAsFixed(2) : '',
    );
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(
        method: method,
        remainingAmount: _remaining,
        amountController: amountController,
        referenceController: referenceController,
        onAdd: (amount, reference) {
          setState(() {
            _payments.add(PaymentEntry(
              method: method,
              amount: amount,
              reference: reference,
            ));
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _removePayment(int index) {
    setState(() {
      _payments.removeAt(index);
    });
  }

  Future<void> _processPayments() async {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falta pagar \$${_remaining.toStringAsFixed(2)}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentsData = _payments.map((payment) {
        final data = {
          'payment_method_id': payment.method.id,
          'amount': payment.amount,
          'cash_register_id': widget.cashRegisterId,
        };
        
        if (payment.reference != null && payment.reference!.isNotEmpty) {
          // Casting explícito a dynamic para evitar error de tipo
          final Map<String, dynamic> dataMap = data;
          dataMap['reference'] = payment.reference;
        }
        
        // Calcular cambio solo para efectivo si hay excedente
        if (payment.method.name == 'Efectivo' && _totalPaid > widget.orderTotal) {
          final change = _totalPaid - widget.orderTotal;
          data['amount_received'] = payment.amount;
          data['change_given'] = change;
        }
        
        return data;
      }).toList();

      final response = await ApiService.processMultiplePayments(
        orderId: widget.orderId,
        payments: paymentsData,
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago procesado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onPaymentComplete();
        Navigator.of(context).pop();
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
        title: const Text('Procesar Pago'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          const Divider(height: 1),
          Expanded(
            child: _payments.isEmpty
                ? _buildEmptyState()
                : _buildPaymentsList(),
          ),
          const Divider(height: 1),
          _buildPaymentMethodsGrid(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a Pagar:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${widget.orderTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pagado:',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              Text(
                '\$${_totalPaid.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isComplete ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restante:',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              Text(
                '\$${_remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _remaining > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (_isComplete && _totalPaid > widget.orderTotal) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cambio:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${(_totalPaid - widget.orderTotal).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay pagos agregados',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccione un método de pago abajo',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: payment.method.color.withOpacity(0.2),
              child: Icon(payment.method.icon, color: payment.method.color),
            ),
            title: Text(
              payment.method.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: payment.reference != null
                ? Text('Ref: ${payment.reference}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePayment(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métodos de Pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              return _buildPaymentMethodButton(method);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(PaymentMethod method) {
    return InkWell(
      onTap: _remaining > 0 ? () => _addPayment(method) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: method.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: method.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(method.icon, color: method.color, size: 20),
            const SizedBox(width: 8),
            Text(
              method.name,
              style: TextStyle(
                color: method.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
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
                onPressed: _isComplete && !_isProcessing ? _processPayments : null,
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
                label: Text(
                  _isProcessing
                      ? 'Procesando...'
                      : _isComplete
                          ? 'Completar Pago'
                          : 'Falta \$${_remaining.toStringAsFixed(2)}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _isComplete ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DIÁLOGO PARA AGREGAR PAGO
// ============================================================================

class _AddPaymentDialog extends StatefulWidget {
  final PaymentMethod method;
  final double remainingAmount;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final Function(double amount, String? reference) onAdd;

  const _AddPaymentDialog({
    required this.method,
    required this.remainingAmount,
    required this.amountController,
    required this.referenceController,
    required this.onAdd,
  });

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Seleccionar todo el texto después de que el autofocus se aplique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.amountController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.amountController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool requiresReference = widget.method.name != 'Efectivo';

    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.method.icon, color: widget.method.color),
          const SizedBox(width: 12),
          Text('Pago con ${widget.method.name}'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.amountController,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
                helperText: 'Restante: \$${widget.remainingAmount.toStringAsFixed(2)}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
            if (requiresReference) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referencia / Últimos 4 dígitos',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 1234',
                ),
                validator: requiresReference
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese la referencia';
                        }
                        return null;
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(widget.amountController.text);
              final reference = widget.referenceController.text.isEmpty
                  ? null
                  : widget.referenceController.text;
              widget.onAdd(amount, reference);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.method.color,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MODELOS
// ============================================================================

class PaymentMethod {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class PaymentEntry {
  final PaymentMethod method;
  final double amount;
  final String? reference;

  PaymentEntry({
    required this.method,
    required this.amount,
    this.reference,
  });
}
