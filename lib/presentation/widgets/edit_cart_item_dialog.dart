// presentation/widgets/edit_cart_item_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/cart_item.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart'; // ExtraSelector

class EditCartItemDialog extends StatefulWidget {
  const EditCartItemDialog({super.key, required this.index});
  final int index;

  /// Úsalo así: await EditCartItemDialog.show(context, index: i);
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

  // estado editable
  List<int> _ids = [];
  List<String> _labels = [];
  int _qty = 1;
  String? _note;
  double _modsExtra = 0.0; // suma $ de modificadores (opcional)

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartModel>();
    _original = cart.items[widget.index];

    _ids    = List<int>.from(_original.modifierIds);
    _labels = List<String>.from(_original.modifierLabels);
    _qty    = _original.qty;
    _note   = _original.note;
    // _modsExtra: si ya lo guardas en CartItem, cárgalo aquí
  }

  double get _itemSubtotal => (_original.unitPrice + _modsExtra) * _qty;

  @override
  Widget build(BuildContext context) {
    final cart  = context.watch<CartModel>();
    final taxRt = cart.taxRate; // 0.16 típicamente

    final tax   = double.parse((_itemSubtotal * taxRt).toStringAsFixed(2));
    final total = _itemSubtotal + tax;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        height: 560,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _original.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Cuerpo tipo product_description
            Expanded(
              child: Row(
                children: [
                  // Imagen del producto
                  _ImagePane(imagePath: _original.imagePath),

                  // Columna derecha (info + selector)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // nombre + precio c/u
                          Text(_original.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('\$${_original.unitPrice.toStringAsFixed(2)} c/u',
                              style: const TextStyle(fontSize: 13, color: Colors.black54)),

                          // descripción (si la tienes en CartItem)
                          if ((_original.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _original.description!,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 12),
                          const Divider(height: 24),

                          // Selector (mods + qty + nota) con valores iniciales
                          Expanded(
                            child: SingleChildScrollView(
                              child: ExtraSelector(
                                productId: _original.productId,
                                initialSelectedIds: _ids,
                                initialQty: _qty,
                                initialNote: _note,
                                onChanged: (ids) => setState(() => _ids = ids),
                                onLabelsChanged: (lbls) => setState(() => _labels = lbls),
                                onQtyChanged: (q) => setState(() => _qty = q),
                                onNoteChanged: (n) => setState(() => _note = n),
                                // Si tu selector puede calcular el total extra, emítelo:
                                onExtraTotalChanged: (extra) => setState(() => _modsExtra = extra),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Totales + acciones
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _totalRow('Subtotal', _itemSubtotal),
                  _totalRow('IVA (16%)', tax),
                  _totalRow('Total', total, bold: true),
                  const SizedBox(height: 12),
                  Row(
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
                              description: _original.description, // si lo agregaste al modelo
                              unitPrice: _original.unitPrice,
                              qty: _qty,
                              modifierIds: _ids,
                              modifierLabels: _labels,
                              note: _note,
                              imagePath: _original.imagePath,
                              // Si guardas el total de extras por línea en el item:
                              // modifierExtra: _modsExtra,
                            );
                            context.read<CartModel>().replaceAt(widget.index, updated);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w800) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _ImagePane extends StatelessWidget {
  const _ImagePane({required this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath ?? '';
    final isNetwork = path.startsWith('http');

    Widget img;
    if (path.isEmpty) {
      img = Container(
        width: 280, height: double.infinity,
        color: Colors.white,
        alignment: Alignment.topCenter,
        child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 64),
      );
    } else {
      img = Container(
        width: 280,
        color: Colors.white,
        alignment: Alignment.topCenter,
        child: isNetwork
            ? Image.network(path, width: 280, fit: BoxFit.cover)
            : Image.asset(path, width: 280, fit: BoxFit.cover),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12), bottomLeft: Radius.circular(12),
      ),
      child: img,
    );
  }
}
