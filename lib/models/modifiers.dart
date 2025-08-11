
class ModifierOption {
  final int id;
  final String name;

  ModifierOption({required this.id, required this.name});

  factory ModifierOption.fromJson(Map<String, dynamic> json) =>
      ModifierOption(id: json['id'], name: json['name']);
}

enum SelectionType { radio, checkbox }

SelectionType selectionTypeFromString(String v) {
  return v.toLowerCase() == 'radio' ? SelectionType.radio : SelectionType.checkbox;
}

class ModifierGroup {
  final String type; // ej: "Aderezos"
  final SelectionType selectionType;
  final List<ModifierOption> modifiers;

  ModifierGroup({
    required this.type,
    required this.selectionType,
    required this.modifiers,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
        type: json['type'],
        selectionType: selectionTypeFromString(json['selection_type']),
        modifiers: (json['modifiers'] as List)
            .map((m) => ModifierOption.fromJson(m))
            .toList(),
      );
}
