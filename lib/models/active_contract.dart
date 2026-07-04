class ActiveContract {
  final int? id;
  final int profileId;
  final int targetTemplateId;
  final int missionTypeId;
  final int defense;
  final int eptsReward;
  final int trustReward;
  final String? expiresAt;
  final bool isCompleted;
  final bool isHoneypot;

  const ActiveContract({
    this.id,
    required this.profileId,
    required this.targetTemplateId,
    required this.missionTypeId,
    required this.defense,
    required this.eptsReward,
    required this.trustReward,
    this.expiresAt,
    this.isCompleted = false,
    this.isHoneypot = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'target_template_id': targetTemplateId,
        'mission_type_id': missionTypeId,
        'defense': defense,
        'epts_reward': eptsReward,
        'trust_reward': trustReward,
        'expires_at': expiresAt,
        'is_completed': isCompleted ? 1 : 0,
        'is_honeypot': isHoneypot ? 1 : 0,
      };

  factory ActiveContract.fromMap(Map<String, dynamic> m) => ActiveContract(
        id: m['id'] as int?,
        profileId: m['profile_id'] as int,
        targetTemplateId: m['target_template_id'] as int,
        missionTypeId: m['mission_type_id'] as int,
        defense: m['defense'] as int,
        eptsReward: m['epts_reward'] as int,
        trustReward: m['trust_reward'] as int,
        expiresAt: m['expires_at'] as String?,
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        isHoneypot: (m['is_honeypot'] as int? ?? 0) == 1,
      );
}

/// Represents the full metadata projection of an active contract
/// joined with its catalog templates and type descriptors.
class ContractDetails {
  final int id;
  final int profileId;
  final int targetTemplateId;
  final int missionTypeId;
  final int defense;
  final int eptsReward;
  final int trustReward;
  final String? expiresAt;
  final bool isCompleted;

  /// A trap contract seeded once wanted crosses the honeypot threshold
  /// (see [WantedEffects]). Never surfaced in the UI ahead of time — an
  /// attack against it always fails with an elevated wanted penalty,
  /// regardless of the minigame outcome.
  final bool isHoneypot;

  // Joined Target Template details
  final String targetName;
  final int targetRequiredLevel;
  final String customMechanicsJson;

  // Joined Target Type details
  final int targetTypeId;
  final String targetTypeName;
  final int targetBaseTraceSpeed;
  final double targetRiskMultiplier;

  // Joined Mission Type details
  final String missionName;
  final String missionDescription;
  final int missionPrimarySoftTypeId;

  const ContractDetails({
    required this.id,
    required this.profileId,
    required this.targetTemplateId,
    required this.missionTypeId,
    required this.defense,
    required this.eptsReward,
    required this.trustReward,
    this.expiresAt,
    required this.isCompleted,
    this.isHoneypot = false,
    required this.targetName,
    required this.targetRequiredLevel,
    required this.customMechanicsJson,
    required this.targetTypeId,
    required this.targetTypeName,
    required this.targetBaseTraceSpeed,
    required this.targetRiskMultiplier,
    required this.missionName,
    required this.missionDescription,
    required this.missionPrimarySoftTypeId,
  });

  factory ContractDetails.fromMap(Map<String, dynamic> m) => ContractDetails(
        id: m['id'] as int,
        profileId: m['profile_id'] as int,
        targetTemplateId: m['target_template_id'] as int,
        missionTypeId: m['mission_type_id'] as int,
        defense: m['defense'] as int,
        eptsReward: m['epts_reward'] as int,
        trustReward: m['trust_reward'] as int,
        expiresAt: m['expires_at'] as String?,
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        isHoneypot: (m['is_honeypot'] as int? ?? 0) == 1,
        targetName: m['target_name'] as String,
        targetRequiredLevel: m['target_required_level'] as int,
        customMechanicsJson: m['target_custom_mechanics'] as String? ?? '{}',
        targetTypeId: m['target_type_id'] as int,
        targetTypeName: m['target_type_name'] as String,
        targetBaseTraceSpeed: m['target_base_trace_speed'] as int,
        targetRiskMultiplier: (m['target_risk_multiplier'] as num).toDouble(),
        missionName: m['mission_name'] as String,
        missionDescription: m['mission_description'] as String,
        missionPrimarySoftTypeId: m['mission_primary_soft_type_id'] as int,
      );
}
