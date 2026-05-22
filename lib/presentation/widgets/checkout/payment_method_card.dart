import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/presentation/pages/payment/payment_screen.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart' as provider;

const Color _mexicanPink = Color(0xFFE91E63);

class PaymentMethodCard extends StatefulWidget {
  const PaymentMethodCard({super.key});

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<PaymentMethodCard> {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSending = false; // loading guard — evita doble tap en "Enviar a cocina"

  InputDecoration _inputDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText:  hint,
      isDense:   true,
      filled:    true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _mexicanPink, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
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
    final cart    = context.watch<CartModel>();
    final tableId = cart.tableId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: _mexicanPink, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Datos del cliente',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D)),
                    ),
                    const SizedBox(width: 6),
                    Text('(opcional)', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(label: 'Nombre', hint: 'Ej: Maria Lopez'),
                  onChanged: (v) => context.read<PaymentModel>().setClientName(v.isEmpty ? null : v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(label: 'Telefono', hint: 'Ej: 5551234567'),
                  onChanged: (v) => context.read<PaymentModel>().setClientPhone(v.isEmpty ? null : v),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(20),
            child: tableId != null
                ? _TableBadge(tableId: tableId)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment_rounded, color: _mexicanPink, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Metodo de pago',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PaymentOption(
                        icon: Icons.attach_money_rounded, label: 'Efectivo',
                        subtitle: 'Pago en caja al recoger', selected: payment.isCash,
                        onTap: () => context.read<PaymentModel>().setMethod(PaymentMethod.cash),
                      ),
                      const SizedBox(height: 10),
                      _PaymentOption(
                        icon: Icons.credit_card_rounded, label: 'Tarjeta',
                        subtitle: 'Debito o credito', selected: payment.isCard,
                        onTap: () => context.read<PaymentModel>().setMethod(PaymentMethod.card),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 68,
              child: ElevatedButton(
                onPressed: _isSending
                    ? null
                    : () async {
                        if (cart.items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tu carrito esta vacio')),
                          );
                          return;
                        }
                        if (tableId != null) {
                          await _sendToKitchen(context);
                          return;
                        }
                        // Para llevar sin nombre → pedir nombre primero
                        final paymentRead = context.read<PaymentModel>();
                        final needsName   = cart.orderType == OrderType.takeAway &&
                            (paymentRead.clientName == null || paymentRead.clientName!.trim().isEmpty);
                        if (needsName) {
                          await _askClientName(context);
                          return;
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(tableId: cart.tableId)));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mexicanPink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _mexicanPink.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            tableId != null ? 'Enviar a cocina' : 'Confirmar y pagar',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _askClientName(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String typedName = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 32,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // handle pill
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 28),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),

                  // icono
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: _mexicanPink.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: _mexicanPink, size: 30),
                  ),
                  const SizedBox(height: 20),

                  // titulo
                  const Text(
                    '\u00bfA nombre de\nqui\u00e9n la orden?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D0D0D),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para pedidos para llevar necesitamos\nidentificar tu orden',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 32),

                  // campo de texto gigante
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    cursorColor: _mexicanPink,
                    decoration: InputDecoration(
                      hintText: 'Tu nombre...',
                      hintStyle: TextStyle(fontSize: 28, color: Colors.grey[300], fontWeight: FontWeight.w400),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 2),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: _mexicanPink, width: 2),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setSheetState(() => typedName = v.trim()),
                  ),
                  const SizedBox(height: 32),

                  // boton continuar
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: typedName.length >= 3
                            ? () {
                                context.read<PaymentModel>().setClientName(typedName);
                                _nameController.text = typedName;
                                Navigator.pop(sheetCtx);
                                final cart = context.read<CartModel>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PaymentScreen(tableId: cart.tableId)),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mexicanPink,
                          disabledBackgroundColor: Colors.grey[200],
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[400],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continuar al Pago',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendToKitchen(BuildContext context) async {
    final cart       = context.read<CartModel>();
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final tipModel   = Provider.of<provider.TipModel>(context, listen: false);
    final tableId    = cart.tableId;

    if (tableId == null) return;

    // Activar loading en el botón
    setState(() => _isSending = true);

    try {
      // Construir lista de items con hash único de ingredientes
      final items = cart.items.map((item) => {
        'product_id': item.productId,
        'quantity':   item.qty,
        'unit_price': item.unitPrice,
        'subtotal':   item.unitPrice * item.qty,
        'notes':      item.note ?? '',
        'modifiers':  item.modifierIds,
      }).toList();

      // POST /api/tables/{id}/open con waiter_id e items
      await ApiService.openTable(
        tableId,
        waiterId: posProvider.userId,
        items: items,
      );

      if (!context.mounted) return;

      // Limpiar estado local
      tipModel.setTipRate(0.0);
      cart.clear();
      cart.setTableId(null);
      context.read<PaymentModel>().reset();

      // SnackBar de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                '¡Orden mandada a cocina!',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // Regresar al mapa de mesas eliminando todas las rutas intermedias
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/waiter',
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _TableBadge extends StatelessWidget {
  const _TableBadge({required this.tableId});
  final int tableId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant_rounded, color: Colors.blue.shade600, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mesa asignada', style: TextStyle(fontSize: 12, color: Colors.blue.shade400)),
              Text('Mesa #$tableId', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({required this.icon, required this.label, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? _mexicanPink.withValues(alpha: 0.04) : Colors.grey[50],
          border: Border.all(color: selected ? _mexicanPink : Colors.grey.shade200, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: selected ? _mexicanPink.withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: selected ? _mexicanPink : Colors.grey[600]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF0D0D0D) : Colors.grey[700])),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected
                  ? const Icon(Icons.check_circle_rounded, key: ValueKey(true), color: _mexicanPink, size: 22)
                  : Icon(Icons.circle_outlined, key: const ValueKey(false), color: Colors.grey.shade300, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
