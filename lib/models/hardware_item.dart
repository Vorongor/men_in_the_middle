class HardwareItem {
  final int? id;
  final String name;
  final String hwType;
  final String description;
  final int basePrice;
  final String currencyType;
  final int reqLevel;
  final int reqBlackTrust;
  final int initComputePower;
  final int initPowerDraw;
  final int sockets;

  const HardwareItem({
    this.id,
    required this.name,
    required this.hwType,
    required this.description,
    required this.basePrice,
    this.currencyType = 'EPTS',
    this.reqLevel = 1,
    this.reqBlackTrust = 0,
    required this.initComputePower,
    required this.initPowerDraw,
    this.sockets = 1,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'hw_type': hwType,
        'description': description,
        'base_price': basePrice,
        'currency_type': currencyType,
        'req_level': reqLevel,
        'req_black_trust': reqBlackTrust,
        'init_compute_power': initComputePower,
        'init_power_draw': initPowerDraw,
        'sockets': sockets,
      };

  factory HardwareItem.fromMap(Map<String, dynamic> m) => HardwareItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        hwType: m['hw_type'] as String,
        description: m['description'] as String,
        basePrice: m['base_price'] as int,
        currencyType: m['currency_type'] as String? ?? 'EPTS',
        reqLevel: m['req_level'] as int? ?? 1,
        reqBlackTrust: m['req_black_trust'] as int? ?? 0,
        initComputePower: m['init_compute_power'] as int,
        initPowerDraw: m['init_power_draw'] as int,
        sockets: m['sockets'] as int? ?? 1,
      );
}
