class EconomyTuning {
  final int boardRefreshFee;
  final double sellRatio;
  final int contractTtlHours;
  final int insuranceMinReward;

  const EconomyTuning({
    required this.boardRefreshFee,
    required this.sellRatio,
    required this.contractTtlHours,
    required this.insuranceMinReward,
  });

  factory EconomyTuning.fromMap(Map<String, dynamic> map) {
    return EconomyTuning(
      boardRefreshFee: map['board_refresh_fee'] as int,
      sellRatio: (map['sell_ratio'] as num).toDouble(),
      contractTtlHours: map['contract_ttl_hours'] as int,
      insuranceMinReward: map['insurance_min_reward'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'board_refresh_fee': boardRefreshFee,
        'sell_ratio': sellRatio,
        'contract_ttl_hours': contractTtlHours,
        'insurance_min_reward': insuranceMinReward,
      };
}
