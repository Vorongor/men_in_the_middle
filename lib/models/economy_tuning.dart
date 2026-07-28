import 'dart:convert';

import 'package:sqflite/sqflite.dart';

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

  /// Fallback used when `meta.economy_tuning` has not been seeded yet.
  ///
  /// Single source of truth: this literal used to be copy-pasted into six
  /// call sites, so tweaking a default meant finding all six — and the UI
  /// could quote one number while the transaction charged another.
  /// Real values live in `assets/data/catalog/economy.json`.
  static const defaults = EconomyTuning(
    boardRefreshFee: 10,
    sellRatio: 0.5,
    contractTtlHours: 24,
    insuranceMinReward: 10,
  );

  /// Reads tuning from the `meta` table, falling back to [defaults].
  ///
  /// Takes a [DatabaseExecutor] so it works with both a database and an open
  /// transaction — the sell paths need the latter.
  static Future<EconomyTuning> load(DatabaseExecutor db) async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: ['economy_tuning']);
    if (rows.isEmpty) return defaults;
    return EconomyTuning.fromMap(
      jsonDecode(rows.first['value'] as String) as Map<String, dynamic>,
    );
  }

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
