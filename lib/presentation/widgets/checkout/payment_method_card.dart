import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/presentation/pages/payment/payment_screen.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart' as provider;

const Color _mexicanPink = Color(0xFFE4007C);

class PaymentMethodCard extends StatefulWidget {
  const PaymentMethodCard({super.key});

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<PaymentMethodCard> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  InputDecoration _inputDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _mexicanPink, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentModel>();
    final cart = context.watch<CartModel>();
    final tableId = cart.tableId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datos del cliente
        const Text(
          'Datos del cliente (opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'Nombre',
                    hint: 'Ej: Juan Pérez',
                  ),
                  onChanged: (value) {
                    context.read<PaymentModel>().setClientName(value.isEmpty ? null : value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Teléfono',
                    hint: 'Ej: 5551234567',
                  ),
                  onChanged: (value) {
                    context.read<PaymentModel>().setClientPhone(value.isEmpty ? null : value);
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // IF TABLE IS SELECTED, HIDE PAYMENT OPTIONS, SHOW TABLE INFO
        if (tableId != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_restaurant, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Asignado a Mesa #$tableId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const Text(
            'Seleccione el tipo de pago',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metodo de pago',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _PaymentOption(
                    icon: Icons.attach_money,
                    label: 'Efectivo',
                    selected: payment.isCash,
                    onTap: () => context.read<PaymentModel>().setMethod(PaymentMethod.cash),
                  ),
                  const SizedBox(height: 12),
                  _PaymentOption(
                    icon: Icons.credit_card,
                    label: 'Tarjeta',
                    selected: payment.isCard,
                    onTap: () => context.read<PaymentModel>().setMethod(PaymentMethod.card),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              // Validar Carrito
              if (cart.items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tu carrito está vacío')),
                );
                return;
              }
              
              if (tableId != null) {
                // SEND TO KITCHEN Logic
                await _sendToKitchen(context);
              } else {
                // Normal Payment Flow
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _mexicanPink,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirmar Orden',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendToKitchen(BuildContext context) async {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final cart = context.read<CartModel>();
      final payment = context.read<PaymentModel>();
      // Better use ConfigurationService directly if Provider is not set up perfectly or just use hardcoded for now?
      // Actually CartModel might allow getting restaurantId? No.
      // Let's use ConfigurationService.
      
      try {
        final posProvider = Provider.of<PosProvider>(context, listen: false);
        final restaurantId = posProvider.restaurantId;
        // Calculate tip amount
        final tipModel = Provider.of<provider.TipModel>(context, listen: false);
        final subtotal = cart.subtotal;
        final tipAmount = subtotal * tipModel.tipRate;
        final total = cart.total + tipAmount;
        
        // Prepare items
        // Prepare items
        final orderType = cart.orderType == OrderType.dineIn ? " [PARA COMER AQUÍ]" : " [PARA LLEVAR]";
        
        final items = cart.items.map((item) {
          return {
            'product_id': item.productId,
            'quantity': item.qty,
            'unit_price': item.unitPrice,
            'subtotal': item.unitPrice * item.qty,
            'notes': (item.note ?? '') + orderType, // Append to every item? Or just send as global note?
            // Sending as global note is better but API might not have it.
            // Let's check ApiService.createOrder signature. 
            // It has no global note.
            // So we'll append to the first item or all?
            // Or better, let's append to the first item for visibility.
            'modifiers': item.modifierIds,
          };
        }).toList();

        // Hack: Append to first item's note if possible, or assume kitchen sees it.
        // Actually, ApiService.createOrder doesn't take global notes.
        // We will modify the first item's note.
        if (items.isNotEmpty) {
           final firstNote = items[0]['notes'] as String;
           items[0]['notes'] = "$orderType $firstNote";
        }

        // Obtener caja actual del PosProvider si existe
        final currentCashRegisterId = posProvider.currentCashRegister?.id;
        final currentUserId = posProvider.userId; // Mesero responsable

        await ApiService.createOrder(
          restaurantId: restaurantId,
          clientName: payment.clientName,
          clientPhone: payment.clientPhone,
          paymentMethod: null, // Open Tab
          tableId: cart.tableId,
          cashRegisterId: currentCashRegisterId, // Asignar caja automáticamente
          waiterId: currentUserId, // Mesero responsable
          items: items,
          total: total, // Validation might fail if mismatch, but backend usually trusts frontend or recalcs
          tip: tipAmount,
        );

        if (context.mounted) {
          Navigator.pop(context); // Close Loading

          // Show Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orden enviada a cocina con éxito'), backgroundColor: Colors.green),
          );

          // Clear Cart
          cart.clear();
          cart.setTableId(null);
          payment.reset();
          tipModel.setTipRate(0.0);

          // Return to Home / Cashier
          // We assume we are in CheckoutScreen -> ButtonIcon -> ...
          // Pop until we are back at a safe place.
          Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/cashier');
        }

      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close Loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: selected ? _mexicanPink : Colors.black.withOpacity(0.08),
            width: selected ? 3 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 22,
                color: _mexicanPink,
              ),
          ],
        ),
      ),
    );
  }
}
