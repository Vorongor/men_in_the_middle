/// Wanted-driven gameplay pressure — the alpha's lightweight stand-in for
/// the concept doc's full "Механіка Wanted" (honeypots, raids, price hikes).
/// Pure Dart: every rule here is a plain function of the wanted level so it
/// can be unit-tested and reused by both UI (price display) and repositories
/// (actual charges, contract generation).
class WantedEffects {
  const WantedEffects._();

  /// 25%+: legitimate shops start distrusting you and mark up prices.
  static const int riskTaxThreshold = 25;
  static const double riskTaxMultiplier = 1.25;

  /// 50%+: the board starts seeding a silent trap contract.
  static const int honeypotThreshold = 50;

  /// 100%: too hot — the board locks until wanted comes back down.
  static const int raidThreshold = 100;

  /// Passive cooldown applied on every "clean" (ideal) successful attack.
  static const int passiveCooldown = 1;

  /// Wanted refunded by a successful Clean Up Traces contract.
  static const int cleanUpReduction = 15;

  static bool isRiskTaxed(int wanted) => wanted >= riskTaxThreshold;
  static bool honeypotActive(int wanted) => wanted >= honeypotThreshold;
  static bool isRaided(int wanted) => wanted >= raidThreshold;

  static double priceMultiplier(int wanted) =>
      isRiskTaxed(wanted) ? riskTaxMultiplier : 1.0;

  /// The price actually charged/displayed for a catalog item at the given
  /// wanted level.
  static int effectivePrice(int basePrice, int wanted) =>
      (basePrice * priceMultiplier(wanted)).round();
}
