import 'dart:convert';

/// Validates raw JSON game content catalogs.
/// Throws [FormatException] if any validation rule is violated.
class ContentValidator {
  static void validate({
    required String softwareItemsJson,
    required String hardwareItemsJson,
    required String targetTypesJson,
    required String targetTemplatesJson,
    required String missionTypesJson,
    required String effectivenessJson,
    required String levelCurveJson,
  }) {
    // 1. Parse and cast JSON lists to map lists to avoid dynamic call warnings
    final softItems = (jsonDecode(softwareItemsJson) as List<dynamic>).cast<Map<String, dynamic>>();
    final hardItems = (jsonDecode(hardwareItemsJson) as List<dynamic>).cast<Map<String, dynamic>>();
    final targetTypes = (jsonDecode(targetTypesJson) as List<dynamic>).cast<Map<String, dynamic>>();
    final targetTemplates = (jsonDecode(targetTemplatesJson) as List<dynamic>).cast<Map<String, dynamic>>();
    final missionTypes = (jsonDecode(missionTypesJson) as List<dynamic>).cast<Map<String, dynamic>>();
    final effectiveness = (jsonDecode(effectivenessJson) as List<dynamic>).cast<Map<String, dynamic>>();
    final levelCurve = (jsonDecode(levelCurveJson) as List<dynamic>).cast<Map<String, dynamic>>();

    // 2. Validate Target Types
    final targetTypeIds = <int>{};
    for (final item in targetTypes) {
      final id = item['id'] as int;
      final name = item['name'] as String;
      final speed = item['base_trace_speed'] as int;
      final mult = (item['risk_multiplier'] as num).toDouble();

      if (id <= 0) throw FormatException('Invalid target type id: $id');
      if (name.isEmpty) throw FormatException('Empty target type name for id: $id');
      if (speed < 1) throw FormatException('Invalid base_trace_speed ($speed) for id: $id');
      if (mult < 0) throw FormatException('Invalid risk_multiplier ($mult) for id: $id');

      targetTypeIds.add(id);
    }

    // 3. Validate Software Types (implicitly 1 to 4)
    final softTypeIds = {1, 2, 3, 4};

    // 4. Validate Mission Types
    for (final item in missionTypes) {
      final id = item['id'] as int;
      final name = item['name'] as String;
      final primarySoftId = item['primary_soft_type_id'] as int;
      final mult = (item['base_reward_mult'] as num).toDouble();

      if (id <= 0) throw FormatException('Invalid mission type id: $id');
      if (name.isEmpty) throw FormatException('Empty mission type name for id: $id');
      if (!softTypeIds.contains(primarySoftId)) {
        throw FormatException('Mission type $id references invalid primary_soft_type_id: $primarySoftId');
      }
      if (mult < 0) throw FormatException('Invalid base_reward_mult ($mult) for mission $id');
    }

    // 5. Validate Software Items
    for (final item in softItems) {
      final id = item['id'] as int;
      final name = item['name'] as String;
      final typeId = item['soft_type_id'] as int;
      final price = item['base_price'] as int;
      final maxLvl = item['init_max_level'] as int? ?? 5;
      final strategy = item['level_up_strategy'] as Map<String, dynamic>;

      if (id <= 0) throw FormatException('Invalid software item id: $id');
      if (name.isEmpty) throw FormatException('Empty software name for id: $id');
      if (!softTypeIds.contains(typeId)) {
        throw FormatException('Software item $id references invalid soft_type_id: $typeId');
      }
      if (price < 0) throw FormatException('Negative base_price ($price) for soft item $id');
      if (maxLvl < 1) throw FormatException('Invalid init_max_level ($maxLvl) for soft item $id');

      // Verify strategy maps expected level keys
      for (var l = 2; l <= maxLvl; l++) {
        if (!strategy.containsKey(l.toString())) {
          throw FormatException('Software item $id levelUpStrategy missing mapping for level $l');
        }
      }
    }

    // 6. Validate Hardware Items
    final hwTypes = {'CPU', 'RAM', 'NET', 'GPU', 'IO'};
    for (final item in hardItems) {
      final id = item['id'] as int;
      final name = item['name'] as String;
      final type = item['hw_type'] as String;
      final price = item['base_price'] as int;

      if (id <= 0) throw FormatException('Invalid hardware item id: $id');
      if (name.isEmpty) throw FormatException('Empty hardware name for id: $id');
      if (!hwTypes.contains(type)) {
        throw FormatException('Hardware item $id has invalid hw_type: $type');
      }
      if (price < 0) throw FormatException('Negative base_price ($price) for hardware item $id');
    }

    // 7. Validate Target Templates
    for (final item in targetTemplates) {
      final id = item['id'] as int;
      final name = item['name'] as String;
      final typeId = item['type_id'] as int;
      final reqLvl = item['required_level'] as int;
      final defense = item['base_defense'] as int;
      final epts = item['epts_reward'] as int;
      final trust = item['trust_reward'] as int;

      if (id <= 0) throw FormatException('Invalid target template id: $id');
      if (name.isEmpty) throw FormatException('Empty target template name for id: $id');
      if (!targetTypeIds.contains(typeId)) {
        throw FormatException('Target template $id references invalid type_id: $typeId');
      }
      if (reqLvl < 1 || reqLvl > 10) {
        throw FormatException('Invalid required_level ($reqLvl) for target template $id');
      }
      if (defense < 1) throw FormatException('Invalid base_defense ($defense) for target template $id');
      if (epts < 0) throw FormatException('Negative epts_reward ($epts) for target template $id');
      if (trust < 0) throw FormatException('Negative trust_reward ($trust) for target template $id');
    }

    // 8. Validate Effectiveness Matrix
    // Must cover 4 soft types * 7 target types = 28 combinations
    final matrixKeys = <String>{};
    for (final item in effectiveness) {
      final softId = item['soft_type_id'] as int;
      final targetId = item['target_type_id'] as int;
      final dmg = (item['damage_mult'] as num).toDouble();
      final trace = (item['trace_mult'] as num).toDouble();

      if (!softTypeIds.contains(softId)) {
        throw FormatException('Effectiveness matrix references invalid soft_type_id: $softId');
      }
      if (!targetTypeIds.contains(targetId)) {
        throw FormatException('Effectiveness matrix references invalid target_type_id: $targetId');
      }
      if (dmg < 0) throw FormatException('Negative damage_mult ($dmg) for combination $softId -> $targetId');
      if (trace < 0) throw FormatException('Negative trace_mult ($trace) for combination $softId -> $targetId');

      matrixKeys.add('$softId-$targetId');
    }

    final expectedCombinations = softTypeIds.length * targetTypeIds.length;
    if (matrixKeys.length < expectedCombinations) {
      throw FormatException(
          'Effectiveness matrix is incomplete. Got ${matrixKeys.length} combinations, expected $expectedCombinations.');
    }

    // 9. Validate Level Curve
    final levelsFound = <int>{};
    for (final item in levelCurve) {
      final lvl = item['level'] as int;
      final exp = item['req_exp'] as int;

      if (lvl < 1 || lvl > 10) throw FormatException('Invalid level curve level: $lvl');
      if (exp < 0) throw FormatException('Negative req_exp ($exp) for level $lvl');

      levelsFound.add(lvl);
    }
    for (var l = 1; l <= 10; l++) {
      if (!levelsFound.contains(l)) {
        throw FormatException('Level curve missing entry for level $l');
      }
    }
  }
}
