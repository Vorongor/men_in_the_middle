import 'hardware_item.dart';

class UserHardware {
  final int? id;
  final int profileId;
  final int itemId;
  final int currentLevel;
  final int computePower;
  final int powerDraw;
  final int modificatorSockets;

  const UserHardware({
    this.id,
    required this.profileId,
    required this.itemId,
    this.currentLevel = 1,
    required this.computePower,
    required this.powerDraw,
    this.modificatorSockets = 1,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'item_id': itemId,
        'current_level': currentLevel,
        'compute_power': computePower,
        'power_draw': powerDraw,
        'modificator_sockets': modificatorSockets,
      };

  factory UserHardware.fromMap(Map<String, dynamic> m) => UserHardware(
        id: m['id'] as int?,
        profileId: m['profile_id'] as int,
        itemId: m['item_id'] as int,
        currentLevel: m['current_level'] as int? ?? 1,
        computePower: m['compute_power'] as int,
        powerDraw: m['power_draw'] as int,
        modificatorSockets: m['modificator_sockets'] as int? ?? 1,
      );
}

/// Represents a combined model of owned hardware and its catalog definition.
class OwnedHardware {
  final UserHardware userHardware;
  final HardwareItem catalogItem;

  const OwnedHardware({
    required this.userHardware,
    required this.catalogItem,
  });
}
