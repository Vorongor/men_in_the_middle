class AttackLogEntry {
  final int? id;
  final int profileId;
  final int targetTemplateId;
  final int missionTypeId;
  final String result;
  final int eptsDelta;
  final int wantedDelta;
  final int trustDelta;
  final String? createdAt;

  const AttackLogEntry({
    this.id,
    required this.profileId,
    required this.targetTemplateId,
    required this.missionTypeId,
    required this.result,
    required this.eptsDelta,
    required this.wantedDelta,
    required this.trustDelta,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'target_template_id': targetTemplateId,
        'mission_type_id': missionTypeId,
        'result': result,
        'epts_delta': eptsDelta,
        'wanted_delta': wantedDelta,
        'trust_delta': trustDelta,
        if (createdAt != null) 'created_at': createdAt,
      };

  factory AttackLogEntry.fromMap(Map<String, dynamic> m) => AttackLogEntry(
        id: m['id'] as int?,
        profileId: m['profile_id'] as int,
        targetTemplateId: m['target_template_id'] as int,
        missionTypeId: m['mission_type_id'] as int,
        result: m['result'] as String,
        eptsDelta: m['epts_delta'] as int,
        wantedDelta: m['wanted_delta'] as int,
        trustDelta: m['trust_delta'] as int,
        createdAt: m['created_at'] as String?,
      );
}
