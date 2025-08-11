import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/models/modifiers.dart';

class ExtraSelector extends StatefulWidget {
  const ExtraSelector({
    super.key,
    required this.productId,
  });

  final int productId;

  @override
  State<ExtraSelector> createState() => _ExtraSelectorState();
}

class _ExtraSelectorState extends State<ExtraSelector> {
  bool _loading = true;
  String? _error;

  // Todos los grupos devueltos por la API
  List<ModifierGroup> _groups = [];

  // Estado de selección por grupo
  final Map<int, int?> _radioSelectedByGroup = {};     // groupIndex -> optionId
  final Map<int, Set<int>> _checkSelectedByGroup = {}; // groupIndex -> {optionIds}

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  // Importante: recargar si cambia el producto
  @override
  void didUpdateWidget(covariant ExtraSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _loadFromApi();
    }
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
      debugPrint('Grupos recibidos: ${groups.length}');

      // Inicializa estado según el tipo de grupo
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
    } catch (e) {
      debugPrint('ERROR _loadFromApi: $e');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
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
    if (_groups.isEmpty) return const SizedBox.shrink();

    // === MISMA UI, pero para TODOS los grupos ===
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int gi = 0; gi < _groups.length; gi++) ...[
            Text(
              _groups[gi].type, // título viene del backend
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_groups[gi].selectionType == SelectionType.radio)
              ..._groups[gi].modifiers.map((m) {
                return RadioListTile<int>(
                  title: Text(m.name),
                  value: m.id,
                  groupValue: _radioSelectedByGroup[gi],
                  activeColor: Colors.redAccent,
                  onChanged: (v) => setState(() => _radioSelectedByGroup[gi] = v),
                );
              })
            else
              ..._groups[gi].modifiers.map((m) {
                final set = _checkSelectedByGroup[gi]!;
                final checked = set.contains(m.id);
                return CheckboxListTile(
                  title: Text(m.name),
                  value: checked,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() {
                    if (v == true) set.add(m.id);
                    else set.remove(m.id);
                  }),
                );
              }),

            const Divider(height: 32),
          ],
        ],
      ),
    );
  }
}
