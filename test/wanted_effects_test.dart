// Pure unit tests: no Flutter binding needed.
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/utils/wanted_effects.dart';

void main() {
  group('WantedEffects.priceMultiplier / effectivePrice', () {
    test('below the risk-tax threshold, price is unchanged', () {
      expect(WantedEffects.priceMultiplier(0), 1.0);
      expect(WantedEffects.priceMultiplier(24), 1.0);
      expect(WantedEffects.effectivePrice(200, 24), 200);
    });

    test('at and above the risk-tax threshold, price is taxed', () {
      expect(WantedEffects.priceMultiplier(25), WantedEffects.riskTaxMultiplier);
      expect(WantedEffects.priceMultiplier(100), WantedEffects.riskTaxMultiplier);
      expect(WantedEffects.effectivePrice(200, 25), 250);
    });

    test('effectivePrice rounds to the nearest whole epts', () {
      // 101 * 1.25 = 126.25 -> rounds to 126
      expect(WantedEffects.effectivePrice(101, 25), 126);
    });
  });

  group('WantedEffects threshold booleans', () {
    test('isRiskTaxed matches the documented threshold', () {
      expect(WantedEffects.isRiskTaxed(24), isFalse);
      expect(WantedEffects.isRiskTaxed(25), isTrue);
    });

    test('honeypotActive matches the documented threshold', () {
      expect(WantedEffects.honeypotActive(49), isFalse);
      expect(WantedEffects.honeypotActive(50), isTrue);
    });

    test('isRaided matches the documented threshold', () {
      expect(WantedEffects.isRaided(99), isFalse);
      expect(WantedEffects.isRaided(100), isTrue);
    });

    test('thresholds are strictly increasing (risk tax < honeypot < raid)', () {
      expect(WantedEffects.riskTaxThreshold, lessThan(WantedEffects.honeypotThreshold));
      expect(WantedEffects.honeypotThreshold, lessThan(WantedEffects.raidThreshold));
    });
  });
}
