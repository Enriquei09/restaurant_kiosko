// presentation/widgets/edit_cart_item_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/cart_item.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart';

const Color _mexicanPink = Color(0xFFE91E63);

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

  // Estado editable
  List<int> _ids = [];
  List<String> _labels = [];
  int _qty = 1;
  String? _note;
  double _modsExtra = 0.0;

  // Control de pasos (espejo de produc_description.dart)
  int _currentStep = 0;
  int _totalSteps = 0;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartModel>();
    _original = cart.items[widget.index];

    _ids    = List<int>.from(_original.modifierIds);
    _labels = List<String>.from(_original.modifierLabels);
    _qty    = _original.qty;
    _note   = _original.note;
  }

  double get _itemSubtotal => (_original.unitPrice + _modsExtra) * _qty;

  // ── Helpers de navegación ──────────────────────────────────────────────────
  bool get _hasSteps   => _totalSteps > 1;
  bool get _isLastStep => _currentStep >= _totalSteps - 1;

  void _goBack() => setState(() => _currentStep--);
  void _goNext() => setState(() => _currentStep++);

  void _onGroupsLoaded(int count) {
    if (count != _totalSteps) {
      setState(() {
        _totalSteps  = count;
        _currentStep = 0;
      });
    }
  }

  // ── Guardar cambios ────────────────────────────────────────────────────────
  void _save() {
    final updated = CartItem(
      productId:      _original.productId,
      name:           _original.name,
      description:    _original.description,
      unitPrice:      _original.unitPrice,
      qty:            _qty,
      modifierIds:    _ids,
      modifierLabels: _labels,
      note:           _note,
      imagePath:      _original.imagePath,
    );
    context.read<CartModel>().replaceAt(widget.index, updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = _itemSubtotal;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 760,
          height: 720,
          color: Colors.white,
          child: Column(
            children: [
              // ── Header con imagen a todo el ancho ──────────────────────────
              _EditHeader(
                item:        _original,
                currentStep: _currentStep,
                totalSteps:  _totalSteps,
                onBack:      _goBack,
              ),

              // ── Indicador de pasos (solo si hay > 1 grupo) ─────────────────
              if (_hasSteps)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: _StepIndicator(
                    totalSteps:  _totalSteps,
                    currentStep: _currentStep,
                  ),
                ),

              // ── Selector de modificadores ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base: \$${_original.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A6D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ExtraSelector(
                        key: ValueKey('edit_${_original.productId}_$_currentStep'),
                        productId:           _original.productId,
                        initialSelectedIds:  _ids,
                        initialQty:          _qty,
                        initialNote:         _note,
                        onChanged:           (ids)   => setState(() => _ids = ids),
                        onLabelsChanged:     (lbls)  => setState(() => _labels = lbls),
                        onQtyChanged:        (q)     => setState(() => _qty = q),
                        onNoteChanged:       (n)     => setState(() => _note = n),
                        onExtraTotalChanged: (extra) => setState(() => _modsExtra = extra),
                        onGroupsLoaded:      _onGroupsLoaded,
                        currentStep:         _hasSteps ? _currentStep : null,
                        showQtyNote:         !_hasSteps || _isLastStep,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Barra inferior: total + botones dinámicos ───────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // ── Botón ATRÁS (visible si hay pasos y no es el primero)
                        if (_hasSteps && _currentStep > 0) ...[
                          SizedBox(
                            height: 64,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _mexicanPink,
                                side: const BorderSide(
                                    color: _mexicanPink, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                              ),
                              icon: const Icon(Icons.arrow_back_ios, size: 18),
                              label: const Text(
                                'Atrás',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                              ),
                              onPressed: _goBack,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // ── Botón SIGUIENTE o GUARDAR CAMBIOS ────────────────
                        if (_hasSteps && !_isLastStep)
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _mexicanPink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.arrow_forward_rounded, size: 22),
                                label: const Text(
                                  'Siguiente',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: _goNext,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _mexicanPink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _save,
                                child: Text(
                                  'Guardar cambios • \$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header con imagen a todo el ancho, botón ← y botón ✕
// Espejo exacto de _HeaderImage en produc_description.dart
// ─────────────────────────────────────────────────────────────────────────────
class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.item,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  final CartItem item;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final path      = item.imagePath ?? '';
    final isNetwork = path.startsWith('http');
    final canGoBack = currentStep > 0;

    Widget imageWidget;
    if (path.isEmpty) {
      imageWidget = _placeholder();
    } else if (isNetwork) {
      imageWidget = Image.network(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    } else {
      imageWidget = Image.asset(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Imagen ────────────────────────────────────────────────────────
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft:  Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: imageWidget,
                ),

                // Botón ← Volver (visible solo en paso > 0)
                if (canGoBack)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: _mexicanPink,
                          size: 20,
                        ),
                        onPressed: onBack,
                        tooltip: 'Paso anterior',
                      ),
                    ),
                  ),

                // Botón ✕ Cerrar (siempre visible)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Nombre y descripción ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.restaurant_menu, size: 64, color: Color(0xFFCCCCCC)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicador de pasos — copia fiel del de produc_description.dart
// ─────────────────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Paso ${currentStep + 1} de $totalSteps',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) {
            final bool isActive = i == currentStep;
            final bool isDone   = i < currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width:  isActive ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive
                    ? _mexicanPink
                    : isDone
                        ? _mexicanPink.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ],
    );
  }
}
