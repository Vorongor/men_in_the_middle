class TargetType {
  final int? id;
  final String name;
  final int baseTraceSpeed;
  final double riskMultiplier;

  /// Optional catalog icon key resolved by `AppIcon` — see
  /// docs/design/icon_presets.md. Null falls back to the target glyph.
  final String? iconKey;

  const TargetType({
    this.id,
    required this.name,
    required this.baseTraceSpeed,
    required this.riskMultiplier,
    this.iconKey,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'base_trace_speed': baseTraceSpeed,
        'risk_multiplier': riskMultiplier,
        'icon_key': iconKey,
      };

  factory TargetType.fromMap(Map<String, dynamic> m) => TargetType(
        id: m['id'] as int?,
        name: m['name'] as String,
        baseTraceSpeed: m['base_trace_speed'] as int,
        riskMultiplier: (m['risk_multiplier'] as num).toDouble(),
        iconKey: m['icon_key'] as String?,
      );
}
