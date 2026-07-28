class MissionType {
  final int? id;
  final String name;
  final String description;
  final int primarySoftTypeId;
  final double baseRewardMult;

  /// Optional catalog icon key resolved by `AppIcon` — see
  /// docs/design/icon_presets.md. Null falls back to the mission glyph.
  final String? iconKey;

  const MissionType({
    this.id,
    required this.name,
    required this.description,
    required this.primarySoftTypeId,
    this.baseRewardMult = 1.0,
    this.iconKey,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'primary_soft_type_id': primarySoftTypeId,
        'base_reward_mult': baseRewardMult,
        'icon_key': iconKey,
      };

  factory MissionType.fromMap(Map<String, dynamic> m) => MissionType(
        id: m['id'] as int?,
        name: m['name'] as String,
        description: m['description'] as String,
        primarySoftTypeId: m['primary_soft_type_id'] as int,
        baseRewardMult: (m['base_reward_mult'] as num?)?.toDouble() ?? 1.0,
        iconKey: m['icon_key'] as String?,
      );
}
