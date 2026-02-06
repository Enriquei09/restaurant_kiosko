import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/api_service.dart';
import '../widgets/supervisor_auth_dialog.dart';

class DiscountDialog extends StatefulWidget {
  final int orderId;
  final double orderTotal;
  final int appliedBy;
  final Function() onApplied;

  const DiscountDialog({
    Key? key,
    required this.orderId,
    required this.orderTotal,
    required this.appliedBy,
    required this.onApplied,
  }) : super(key: key);

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  
  String _discountType = 'percentage'; // 'percentage' o 'fixed'
  bool _isProcessing = false;
  bool _requiresAuth = false;
  double _calculatedDiscount = 0;

  @override
  void initState() {
    super.initState();
    _valueController.addListener(_calculateDiscount);
  }

  void _calculateDiscount() {
    final value = double.tryParse(_valueController.text) ?? 0;
    
    setState(() {
      if (_discountType == 'percentage') {
        _calculatedDiscount = (widget.orderTotal * value) / 100;
      } else {
        _calculatedDiscount = value;
      }
      
      // Requiere autorización si el descuento es > 10% o > $50
      _requiresAuth = _discountType == 'percentage'
          ? value > 10
          : value > 50;
    });
  }

  Future<void> _handleApply() async {
    if (!_formKey.currentState!.validate()) return;

    int? supervisorId;
    
    // Si requiere autorización, solicitar PIN
    if (_requiresAuth) {
      supervisorId = await showSupervisorAuthDialog(
        context: context,
        title: 'Autorización Requerida',
        description: 'Este descuento requiere autorización de supervisor',
      );
      
      if (supervisorId == null) return; // Usuario canceló
    }

    setState(() => _isProcessing = true);

    try {
      final value = double.parse(_valueController.text);
      final response = await ApiService.applyDiscount(
        orderId: widget.orderId,
        appliedBy: widget.appliedBy,
        type: _discountType,
        value: value,
        reason: _reasonController.text,
      );

      if (response['success'] == true && mounted) {
        final discount = response['data'];
        final status = discount['status'];
        
        // Si requiere autorización y tenemos supervisorId, autorizar automáticamente
        if (status == 'pending' && supervisorId != null) {
          await ApiService.authorizeDiscount(
            discountId: discount['id'],
            supervisorId: supervisorId,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved' || supervisorId != null
                  ? 'Descuento aplicado exitosamente'
                  : 'Descuento pendiente de autorización',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onApplied();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newTotal = widget.orderTotal - _calculatedDiscount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
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
                    'Aplicar Descuento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Original:'),
                        Text(
                          '\$${widget.orderTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_calculatedDiscount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Descuento:', style: TextStyle(color: Colors.red)),
                          Text(
                            '- \$${_calculatedDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nuevo Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${newTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tipo de Descuento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'percentage',
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() => _discountType = value!);
                        _calculateDiscount();
                      },
                      title: const Text('Porcentaje'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'fixed',
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() => _discountType = value!);
                        _calculateDiscount();
                      },
                      title: const Text('Monto Fijo'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _discountType == 'percentage'
                      ? 'Porcentaje de Descuento'
                      : 'Monto de Descuento',
                  prefixText: _discountType == 'percentage' ? null : '\$ ',
                  suffixText: _discountType == 'percentage' ? '%' : null,
                  border: const OutlineInputBorder(),
                  helperText: _requiresAuth
                      ? '⚠️ Requiere autorización de supervisor'
                      : 'Auto-aprobado',
                  helperStyle: TextStyle(
                    color: _requiresAuth ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el valor del descuento';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val <= 0) {
                    return 'Valor inválido';
                  }
                  if (_discountType == 'percentage' && val > 100) {
                    return 'El porcentaje no puede ser mayor a 100%';
                  }
                  if (_calculatedDiscount >= widget.orderTotal) {
                    return 'El descuento no puede ser mayor o igual al total';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Razón del Descuento',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Cliente frecuente, promoción, etc.',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese la razón del descuento';
                  }
                  if (value.trim().length < 5) {
                    return 'La razón debe tener al menos 5 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _handleApply,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isProcessing ? 'Aplicando...' : 'Aplicar Descuento'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
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

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

/// Helper function para mostrar el diálogo
Future<void> showDiscountDialog({
  required BuildContext context,
  required int orderId,
  required double orderTotal,
  required int appliedBy,
  required Function() onApplied,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => DiscountDialog(
      orderId: orderId,
      orderTotal: orderTotal,
      appliedBy: appliedBy,
      onApplied: onApplied,
    ),
  );
}
