import 'software_item.dart';

class UserSoftware {
  final int? id;
  final int profileId;
  final int itemId;
  final int currentLevel;
  final int attack;
  final int penetrationAbility;
  final int residualTrace;
  final int modificatorSockets;

  const UserSoftware({
    this.id,
    required this.profileId,
    required this.itemId,
    this.currentLevel = 1,
    required this.attack,
    required this.penetrationAbility,
    required this.residualTrace,
    this.modificatorSockets = 1,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'item_id': itemId,
        'current_level': currentLevel,
        'attack': attack,
        'penetration_ability': penetrationAbility,
        'residual_trace': residualTrace,
        'modificator_sockets': modificatorSockets,
      };

  factory UserSoftware.fromMap(Map<String, dynamic> m) => UserSoftware(
        id: m['id'] as int?,
        profileId: m['profile_id'] as int,
        itemId: m['item_id'] as int,
        currentLevel: m['current_level'] as int? ?? 1,
        attack: m['attack'] as int,
        penetrationAbility: m['penetration_ability'] as int,
        residualTrace: m['residual_trace'] as int,
        modificatorSockets: m['modificator_sockets'] as int? ?? 1,
      );
}

/// Represents a combined model of owned software and its catalog definition.
class OwnedSoftware {
  final UserSoftware userSoftware;
  final SoftwareItem catalogItem;

  const OwnedSoftware({
    required this.userSoftware,
    required this.catalogItem,
  });
}
