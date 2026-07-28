import 'dart:convert';

class SoftwareItem {
  final int? id;
  final String name;
  final int softTypeId;
  final String description;
  final int basePrice;
  final String currencyType;
  final int reqLevel;
  final int reqBlackTrust;
  final int initMaxLevel;
  final int baseAttack;
  final int basePenetration;
  final int baseTrace;
  final int sockets;
  final Map<String, dynamic> levelUpStrategy;

  /// Optional catalog icon key resolved by `AppIcon` — see
  /// docs/design/icon_presets.md. Null falls back to the software glyph.
  final String? iconKey;

  const SoftwareItem({
    this.id,
    required this.name,
    required this.softTypeId,
    required this.description,
    required this.basePrice,
    this.currencyType = 'EPTS',
    this.reqLevel = 1,
    this.reqBlackTrust = 0,
    this.initMaxLevel = 5,
    required this.baseAttack,
    required this.basePenetration,
    required this.baseTrace,
    this.sockets = 1,
    required this.levelUpStrategy,
    this.iconKey,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'soft_type_id': softTypeId,
        'description': description,
        'base_price': basePrice,
        'currency_type': currencyType,
        'req_level': reqLevel,
        'req_black_trust': reqBlackTrust,
        'init_max_level': initMaxLevel,
        'base_attack': baseAttack,
        'base_penetration': basePenetration,
        'base_trace': baseTrace,
        'sockets': sockets,
        'level_up_strategy': jsonEncode(levelUpStrategy),
        'icon_key': iconKey,
      };

  factory SoftwareItem.fromMap(Map<String, dynamic> m) {
    final rawStrategy = m['level_up_strategy'];
    Map<String, dynamic> strategy = {};
    if (rawStrategy is String) {
      strategy = jsonDecode(rawStrategy) as Map<String, dynamic>;
    } else if (rawStrategy is Map<String, dynamic>) {
      strategy = rawStrategy;
    }
    return SoftwareItem(
      id: m['id'] as int?,
      name: m['name'] as String,
      softTypeId: m['soft_type_id'] as int,
      description: m['description'] as String,
      basePrice: m['base_price'] as int,
      currencyType: m['currency_type'] as String? ?? 'EPTS',
      reqLevel: m['req_level'] as int? ?? 1,
      reqBlackTrust: m['req_black_trust'] as int? ?? 0,
      initMaxLevel: m['init_max_level'] as int? ?? 5,
      baseAttack: m['base_attack'] as int,
      basePenetration: m['base_penetration'] as int,
      baseTrace: m['base_trace'] as int,
      sockets: m['sockets'] as int? ?? 1,
      levelUpStrategy: strategy,
      iconKey: m['icon_key'] as String?,
    );
  }
}
