import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/models/modifiers.dart';

/// Selector de extras/modificadores para un producto.
/// - Carga los grupos desde la API: radios y checkboxes.
/// - Expone callbacks para: IDs seleccionados, labels, cantidad, nota
///   y (opcional) total extra de modificadores.
/// - Muestra controles de Cantidad y Nota al final (siempre, aunque no haya grupos).
class ExtraSelector extends StatefulWidget {
  const ExtraSelector({
    super.key,
    required this.productId,
    this.onChanged,              // IDs seleccionados
    this.onLabelsChanged,        // Labels seleccionados
    this.onQtyChanged,           // Cantidad
    this.onNoteChanged,          // Nota
    this.onExtraTotalChanged,    // (opcional) Total $ de modificadores
    this.initialQty = 1,
    this.initialNote,
    this.initialSelectedIds = const [],
  });

  /// ID del producto para consultar sus grupos de modificadores
  final int productId;

  /// Callback: lista de IDs seleccionados (radios + checks)
  final ValueChanged<List<int>>? onChanged;

  /// Callback: labels amigables de los seleccionados (radios + checks)
  final ValueChanged<List<String>>? onLabelsChanged;

  /// Callback: cantidad elegida
  final ValueChanged<int>? onQtyChanged;

  /// Callback: nota (null si vacío)
  final ValueChanged<String?>? onNoteChanged;

  /// (Opcional) Callback con la suma de precios de los modificadores seleccionados
  final ValueChanged<double>? onExtraTotalChanged;

  /// Valor inicial de cantidad
  final int initialQty;

  /// Valor inicial de nota
  final String? initialNote;

  /// IDs de modificadores a preseleccionar al cargar
  final List<int> initialSelectedIds;

  @override
  State<ExtraSelector> createState() => _ExtraSelectorState();
}

class _ExtraSelectorState extends State<ExtraSelector> {
  bool _loading = true;
  String? _error;

  // Grupos devueltos por la API
  List<ModifierGroup> _groups = [];

  // Estado de selección por grupo
  final Map<int, int?> _radioSelectedByGroup = {};      // groupIndex -> optionId
  final Map<int, Set<int>> _checkSelectedByGroup = {};  // groupIndex -> {optionIds}

  // Cantidad y nota locales
  late int _qty;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty;
    _noteCtrl = TextEditingController(text: widget.initialNote ?? '');
    _loadFromApi();
  }

  // Recarga si cambia el producto (y reinicia qty/nota a los valores iniciales)
  @override
  void didUpdateWidget(covariant ExtraSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _qty = widget.initialQty;
      _noteCtrl.text = widget.initialNote ?? '';
      _loadFromApi();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromApi() async {
    setState(() {
      _loading = true;
      _error = null;
      _groups = [];
      _radioSelectedByGroup.clear();
      _checkSelectedByGroup.clear();
    });

    try {
      final groups = await ApiService.fetchModifierGroups(widget.productId);

      // Inicializa estructuras de selección por tipo
      for (int i = 0; i < groups.length; i++) {
        final g = groups[i];
        if (g.selectionType == SelectionType.radio) {
          _radioSelectedByGroup[i] = null;
        } else {
          _checkSelectedByGroup[i] = <int>{};
        }
      }

      setState(() {
        _groups = groups;
        _loading = false;
      });

      // Preseleccionar ids recibidos
      _applyInitialSelectedIds();

      // Notificar estado inicial
      _notifyAll();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyInitialSelectedIds() {
    final init = widget.initialSelectedIds.toSet();
    if (init.isEmpty) return;

    for (int i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      if (g.selectionType == SelectionType.radio) {
        int? chosen;
        for (final m in g.modifiers) {
          if (init.contains(m.id)) {
            chosen = m.id;
            break;
          }
        }
        _radioSelectedByGroup[i] = chosen;
      } else {
        final set = <int>{};
        for (final m in g.modifiers) {
          if (init.contains(m.id)) set.add(m.id);
        }
        _checkSelectedByGroup[i] = set;
      }
    }
  }

  // IDs seleccionados (radios + checks)
  List<int> _selectedIds() {
    final List<int> selected = [];
    // Radios
    _radioSelectedByGroup.forEach((_, optId) {
      if (optId != null) selected.add(optId);
    });
    // Checks
    _checkSelectedByGroup.forEach((_, set) => selected.addAll(set));
    return selected;
  }

  // Labels seleccionados a partir de IDs
  List<String> _selectedLabels(List<int> ids) {
    String? labelFor(int id) {
      for (final g in _groups) {
        for (final m in g.modifiers) {
          if (m.id == id) return m.name;
        }
      }
      return null;
    }
    return ids.map(labelFor).whereType<String>().toList();
  }

  // (Opcional) calcula el total extra de los modificadores seleccionados
  double _calcExtraTotal(List<int> ids) {
    double total = 0.0;

    // TODO: si tu clase Modifier tiene un campo de precio (por ejemplo `price` o `priceDelta`),
    // descomenta alguna de las líneas dentro del loop y ajusta el nombre del campo:
    for (final g in _groups) {
      for (final m in g.modifiers) {
        if (ids.contains(m.id)) {
          // total += m.price;       // <- si tu modelo expone `price`
          // total += m.priceDelta;  // <- o si expone `priceDelta`
          // De lo contrario, deja en 0.0 y maneja el cálculo fuera.
        }
      }
    }

    return total;
  }

  void _notifyAll() {
    final ids = _selectedIds();
    final labels = _selectedLabels(ids);
    widget.onChanged?.call(ids);
    widget.onLabelsChanged?.call(labels);
    widget.onQtyChanged?.call(_qty);
    widget.onNoteChanged?.call(_normalizedNote());
    widget.onExtraTotalChanged?.call(_calcExtraTotal(ids));
  }

  void _notifySelectionOnly() {
    final ids = _selectedIds();
    final labels = _selectedLabels(ids);
    widget.onChanged?.call(ids);
    widget.onLabelsChanged?.call(labels);
    widget.onExtraTotalChanged?.call(_calcExtraTotal(ids));
  }

  String? _normalizedNote() {
    final t = _noteCtrl.text.trim();
    return t.isEmpty ? null : t;
  }

  void _incQty() {
    if (_qty < 100) {
      setState(() => _qty++);
      widget.onQtyChanged?.call(_qty);
    }
  }

  void _decQty() {
    if (_qty > 1) {
      setState(() => _qty--);
      widget.onQtyChanged?.call(_qty);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No se pudieron cargar opciones.\n$_error'),
      );
    }

    // Si no hay grupos, aún mostramos cantidad y nota
    if (_groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: _qtyNoteSection(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int gi = 0; gi < _groups.length; gi++) ...[
            Text(
              _groups[gi].type, // título del grupo (viene del backend)
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Radios
            if (_groups[gi].selectionType == SelectionType.radio)
              ..._groups[gi].modifiers.map((m) {
                return RadioListTile<int>(
                  title: Text(m.name),
                  value: m.id,
                  groupValue: _radioSelectedByGroup[gi],
                  activeColor: Colors.redAccent,
                  onChanged: (v) => setState(() {
                    _radioSelectedByGroup[gi] = v;
                    _notifySelectionOnly();
                  }),
                );
              })

            // Checkboxes
            else
              ..._groups[gi].modifiers.map((m) {
                final set = _checkSelectedByGroup[gi]!;
                final checked = set.contains(m.id);
                return CheckboxListTile(
                  title: Text(m.name),
                  value: checked,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      set.add(m.id);
                    } else {
                      set.remove(m.id);
                    }
                    _notifySelectionOnly();
                  }),
                );
              }),

            const Divider(height: 24),
          ],

          // Controles de cantidad y nota
          _qtyNoteSection(),
        ],
      ),
    );
  }

  /// Sección final con controles de Cantidad y Nota
  Widget _qtyNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cantidad
        Row(
          children: [
            const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _decQty,
              tooltip: 'Disminuir',
            ),
            Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _incQty,
              tooltip: 'Aumentar',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Nota
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => widget.onNoteChanged?.call(_normalizedNote()),
        ),
      ],
    );
  }
}
