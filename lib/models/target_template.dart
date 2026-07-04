import 'dart:convert';

class TargetTemplate {
  final int? id;
  final int typeId;
  final String name;
  final int requiredLevel;
  final int baseDefense;
  final int eptsReward;
  final int trustReward;
  final Map<String, dynamic> customMechanics;

  const TargetTemplate({
    this.id,
    required this.typeId,
    required this.name,
    this.requiredLevel = 1,
    required this.baseDefense,
    required this.eptsReward,
    required this.trustReward,
    required this.customMechanics,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type_id': typeId,
        'name': name,
        'required_level': requiredLevel,
        'base_defense': baseDefense,
        'epts_reward': eptsReward,
        'trust_reward': trustReward,
        'custom_mechanics': jsonEncode(customMechanics),
      };

  factory TargetTemplate.fromMap(Map<String, dynamic> m) {
    final rawMechanics = m['custom_mechanics'];
    Map<String, dynamic> mechanics = {};
    if (rawMechanics is String) {
      mechanics = jsonDecode(rawMechanics) as Map<String, dynamic>;
    } else if (rawMechanics is Map<String, dynamic>) {
      mechanics = rawMechanics;
    }
    return TargetTemplate(
      id: m['id'] as int?,
      typeId: m['type_id'] as int,
      name: m['name'] as String,
      requiredLevel: m['required_level'] as int? ?? 1,
      baseDefense: m['base_defense'] as int,
      eptsReward: m['epts_reward'] as int,
      trustReward: m['trust_reward'] as int,
      customMechanics: mechanics,
    );
  }
}
