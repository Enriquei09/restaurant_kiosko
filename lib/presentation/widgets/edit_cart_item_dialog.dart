import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/models/cart_item.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart'; 

class EditCartItemDialog extends StatefulWidget {
  const EditCartItemDialog({super.key, required this.index});
  final int index;

  static Future<void> show(BuildContext context, {required int index}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditCartItemDialog(index: index),
    );
  }

  @override
  State<EditCartItemDialog> createState() => _EditCartItemDialogState();
}

class _EditCartItemDialogState extends State<EditCartItemDialog> {
  late CartItem _original;
  List<int> _ids = [];
  List<String> _labels = [];
  int _qty = 1;
  String? _note;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartModel>();
    _original = cart.items[widget.index];
    _ids = List<int>.from(_original.modifierIds);
    _labels = List<String>.from(_original.modifierLabels);
    _qty = _original.qty;
    _note = _original.note;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 520,
        height: 640,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_original.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Selector (mods + qty + nota) con valores iniciales
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ExtraSelector(
                    productId: _original.productId,
                    initialSelectedIds: _ids,      // 👈 precarga
                    initialQty: _qty,
                    initialNote: _note,
                    onChanged: (ids) => setState(() => _ids = ids),
                    onLabelsChanged: (lbls) => setState(() => _labels = lbls),
                    onQtyChanged: (q) => setState(() => _qty = q),
                    onNoteChanged: (n) => setState(() => _note = n),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Botones
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = CartItem(
                          productId: _original.productId,
                          name: _original.name,
                          unitPrice: _original.unitPrice,
                          qty: _qty,
                          modifierIds: _ids,
                          modifierLabels: _labels,
                          note: _note,
                          imagePath: _original.imagePath,
                        );
                        context.read<CartModel>().replaceAt(widget.index, updated);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
