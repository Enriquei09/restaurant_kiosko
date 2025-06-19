import 'package:flutter/material.dart';

class ExtraSelector extends StatefulWidget {
  const ExtraSelector({super.key});

  @override
  State<ExtraSelector> createState() => _ExtraSelectorState();
}

class _ExtraSelectorState extends State<ExtraSelector> {
  // Ingredientes extra (Checkbox)
  Map<String, bool> extras = {
    'Cebolla': false,
    'Jitomate': false,
    'Cilantro': false,
  };

  // Picante (Radio)
  String? picanteSeleccionado;

  final List<String> opcionesPicante = ['Salsa Roja', 'Salsa Verde', 'Ambas'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧅 Ingredientes extras',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...extras.entries.map((entry) {
            return CheckboxListTile(
              title: Text(entry.key),
              value: entry.value,
              activeColor: Colors.green,
              onChanged: (bool? selected) {
                setState(() {
                  extras[entry.key] = selected ?? false;
                });
              },
            );
          }),

          const Divider(height: 32),

          const Text(
            '🌶️ ¿Picante?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...opcionesPicante.map((opcion) {
            return RadioListTile(
              title: Text(opcion),
              value: opcion,
              groupValue: picanteSeleccionado,
              activeColor: Colors.redAccent,
              onChanged: (String? value) {
                setState(() {
                  picanteSeleccionado = value;
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
