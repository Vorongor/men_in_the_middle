import '../../models/hardware_item.dart';
import '../../models/software_item.dart';

/// Sell-price arithmetic, in one place and free of any Flutter dependency.
///
/// Deliberately imports nothing but the two plain-Dart catalog models: the
/// balance simulator (`tool/simulate.dart`) runs under a bare `dart run` with
/// no Flutter binding, so it cannot reach into the repository layer. Keeping
/// the formulas here is what lets the transaction, the Workshop screen and the
/// simulator all price items identically instead of each carrying a copy — the
/// bug pattern where a dialog quotes one figure and the payout differs.
abstract final class SellPricing {
  /// Total epts sunk into upgrading a software item to [currentLevel].
  static int softwareUpgradesCost(SoftwareItem catalog, int currentLevel) {
    var total = 0;
    for (var level = 2; level <= currentLevel; level++) {
      final step = catalog.levelUpStrategy[level.toString()] as Map<String, dynamic>?;
      total += step?['cost'] as int? ?? 0;
    }
    return total;
  }

  /// Total epts sunk into upgrading a hardware item to [currentLevel].
  static int hardwareUpgradesCost(HardwareItem catalog, int currentLevel) {
    var total = 0;
    for (var level = 1; level < currentLevel; level++) {
      total += (catalog.basePrice * 0.6 * level).round();
    }
    return total;
  }

  /// Payout for selling owned software: [sellRatio] of the purchase price plus
  /// everything spent upgrading it.
  static int software(double sellRatio, SoftwareItem catalog, int currentLevel) =>
      (sellRatio * (catalog.basePrice + softwareUpgradesCost(catalog, currentLevel)))
          .round();

  /// Hardware counterpart of [software].
  static int hardware(double sellRatio, HardwareItem catalog, int currentLevel) =>
      (sellRatio * (catalog.basePrice + hardwareUpgradesCost(catalog, currentLevel)))
          .round();
}
