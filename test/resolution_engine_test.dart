// Deliberately does NOT call TestWidgetsFlutterBinding.ensureInitialized()
// or touch sqflite/rootBundle: this proves ResolutionEngine has no Flutter
// or DB dependency, as required by docs/planning/step_07_attack_flow.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/game/resolution/resolution_engine.dart';
import 'package:men_in_the_middle/models/active_contract.dart';
import 'package:men_in_the_middle/models/profile.dart';
import 'package:men_in_the_middle/models/software_item.dart';
import 'package:men_in_the_middle/models/user_software.dart';
import 'package:men_in_the_middle/utils/wanted_effects.dart';

Profile _profile({int wanted = 0, int blackTrust = 0}) => Profile(
      id: 1,
      profileId: 'AB12345',
      levelId: 1,
      hardwarePower: 20,
      wanted: wanted,
      blackTrust: blackTrust,
      legend: 'test',
    );

ContractDetails _contract({
  int defense = 100,
  int eptsReward = 300,
  int trustReward = 10,
  double targetRiskMultiplier = 1.0,
  int targetTypeId = 3,
  int missionPrimarySoftTypeId = 1,
  int missionTypeId = 1,
  bool isHoneypot = false,
}) =>
    ContractDetails(
      id: 1,
      profileId: 1,
      targetTemplateId: 1,
      missionTypeId: missionTypeId,
      defense: defense,
      eptsReward: eptsReward,
      trustReward: trustReward,
      isCompleted: false,
      isHoneypot: isHoneypot,
      targetName: 'Test Node',
      targetRequiredLevel: 1,
      customMechanicsJson: '{}',
      targetTypeId: targetTypeId,
      targetTypeName: 'Corporate Employees',
      targetBaseTraceSpeed: 10,
      targetRiskMultiplier: targetRiskMultiplier,
      missionName: 'Data Theft',
      missionDescription: 'desc',
      missionPrimarySoftTypeId: missionPrimarySoftTypeId,
    );

OwnedSoftware _software({int attack = 20, int penetration = 10}) => OwnedSoftware(
      userSoftware: UserSoftware(
        id: 1,
        profileId: 1,
        itemId: 1,
        attack: attack,
        penetrationAbility: penetration,
        residualTrace: 2,
      ),
      catalogItem: const SoftwareItem(
        id: 1,
        name: 'Phishing Mailer',
        softTypeId: 1,
        description: 'desc',
        basePrice: 100,
        baseAttack: 10,
        basePenetration: 5,
        baseTrace: 2,
        levelUpStrategy: {},
      ),
    );

AttackSetup _setup({
  int attack = 20,
  int penetration = 10,
  int hardwarePower = 20,
  double damageMult = 1.0,
  double traceMult = 1.0,
  ContractDetails? contract,
}) =>
    AttackSetup(
      profile: _profile(),
      contract: contract ?? _contract(),
      selectedSoftware: _software(attack: attack, penetration: penetration),
      hardwarePower: hardwarePower,
      damageMult: damageMult,
      traceMult: traceMult,
    );

void main() {
  group('MinigameOutcome.perfect', () {
    test('success with timeRatio > 0.5 is perfect', () {
      expect(const MinigameOutcome(success: true, timeRatio: 0.51).perfect, isTrue);
    });

    test('success with timeRatio exactly 0.5 is NOT perfect (hard hack)', () {
      expect(const MinigameOutcome(success: true, timeRatio: 0.5).perfect, isFalse);
    });

    test('failure is never perfect regardless of timeRatio', () {
      expect(const MinigameOutcome(success: false, timeRatio: 0.99).perfect, isFalse);
    });
  });

  group('ResolutionEngine.resolve — ideal hack', () {
    test('grants full epts, exp, trust and a small passive wanted cooldown', () {
      final setup = _setup(contract: _contract(eptsReward: 300, trustReward: 10, defense: 100));
      final outcome = const MinigameOutcome(success: true, timeRatio: 0.9);

      final res = ResolutionEngine.resolve(setup, outcome);

      expect(res.result, AttackResultKind.success);
      expect(res.eptsDelta, 300);
      expect(res.expDelta, (100 * 0.6).round());
      expect(res.trustDelta, 10);
      expect(res.wantedDelta, -WantedEffects.passiveCooldown);
    });

    test('rolls a bonus drop when dropRoll beats dropChance', () {
      final setup = _setup();
      final outcome = const MinigameOutcome(success: true, timeRatio: 0.9);

      final withDrop = ResolutionEngine.resolve(setup, outcome, dropRoll: 0.01);
      final withoutDrop = ResolutionEngine.resolve(setup, outcome, dropRoll: 0.99);

      expect(withDrop.drops, isNotEmpty);
      expect(withoutDrop.drops, isEmpty);
    });
  });

  group('ResolutionEngine.resolve — hard hack', () {
    test('grants full epts and exp but a flat wanted penalty, no trust', () {
      final setup = _setup(contract: _contract(eptsReward: 300, trustReward: 10, defense: 100));
      final outcome = const MinigameOutcome(success: true, timeRatio: 0.3);

      final res = ResolutionEngine.resolve(setup, outcome);

      expect(res.result, AttackResultKind.hard);
      expect(res.eptsDelta, 300);
      expect(res.expDelta, (100 * 0.6).round());
      expect(res.trustDelta, 0);
      expect(res.wantedDelta, ResolutionEngine.baseWantedGain);
      expect(res.drops, isEmpty);
    });
  });

  group('ResolutionEngine.resolve — failure', () {
    test('grants nothing and scales wanted by risk and trace multipliers', () {
      final setup = _setup(
        contract: _contract(targetRiskMultiplier: 2.0),
        damageMult: 0.2, // wrong tool for this target
      );
      final withHighTrace = AttackSetup(
        profile: setup.profile,
        contract: setup.contract,
        selectedSoftware: setup.selectedSoftware,
        hardwarePower: setup.hardwarePower,
        damageMult: setup.damageMult,
        traceMult: 1.5,
      );
      final outcome = const MinigameOutcome(success: false, timeRatio: 0.0);

      final res = ResolutionEngine.resolve(withHighTrace, outcome);

      expect(res.result, AttackResultKind.fail);
      expect(res.eptsDelta, 0);
      expect(res.expDelta, 0);
      expect(res.trustDelta, 0);
      expect(res.wantedDelta, (ResolutionEngine.baseWantedGain * 2.0 * 1.5).round());
    });

    test('mismatched (x0.2) software still fails the same regardless of damageMult', () {
      // damageMult only shapes effectiveAttack/time budget, not the fail
      // penalty itself — resolve() only sees the minigame's outcome.
      final weakTool = _setup(damageMult: 0.2);
      final strongTool = _setup(damageMult: 2.0);
      final outcome = const MinigameOutcome(success: false, timeRatio: 0.0);

      final weakRes = ResolutionEngine.resolve(weakTool, outcome);
      final strongRes = ResolutionEngine.resolve(strongTool, outcome);

      expect(weakRes.wantedDelta, strongRes.wantedDelta);
    });
  });

  group('ResolutionEngine.effectiveAttack / timeBudgetSeconds', () {
    test('effectiveAttack scales linearly with damageMult', () {
      final setup = _setup(attack: 50, damageMult: 2.0);
      expect(ResolutionEngine.effectiveAttack(setup), 100);
    });

    test('stronger effective attack yields a larger time budget than a weak one', () {
      final weak = _setup(attack: 5, damageMult: 0.2, contract: _contract(defense: 200));
      final strong = _setup(attack: 50, damageMult: 2.0, contract: _contract(defense: 200));

      expect(
        ResolutionEngine.timeBudgetSeconds(strong),
        greaterThan(ResolutionEngine.timeBudgetSeconds(weak)),
      );
    });

    test('being under-equipped on hardware shrinks the time budget', () {
      final contract = _contract(defense: 200);
      final wellEquipped = _setup(hardwarePower: 150, contract: contract);
      final underEquipped = _setup(hardwarePower: 10, contract: contract);

      expect(
        ResolutionEngine.timeBudgetSeconds(underEquipped),
        lessThan(ResolutionEngine.timeBudgetSeconds(wellEquipped)),
      );
    });

    test('time budget is always positive even for a hopeless matchup', () {
      final setup = _setup(attack: 1, penetration: 1, damageMult: 0.2, hardwarePower: 1, contract: _contract(defense: 10000));
      expect(ResolutionEngine.timeBudgetSeconds(setup), greaterThan(0));
    });
  });

  group('ResolutionEngine.resolve — honeypot', () {
    test('always fails with an elevated wanted penalty regardless of a winning outcome', () {
      final setup = _setup(contract: _contract(targetRiskMultiplier: 1.0, isHoneypot: true));
      final outcome = const MinigameOutcome(success: true, timeRatio: 0.95);

      final res = ResolutionEngine.resolve(setup, outcome);

      expect(res.result, AttackResultKind.fail);
      expect(res.eptsDelta, 0);
      expect(res.expDelta, 0);
      expect(
        res.wantedDelta,
        ResolutionEngine.baseWantedGain * ResolutionEngine.honeypotWantedMultiplier,
      );
    });

    test('honeypot penalty is strictly larger than an ordinary failure on the same target', () {
      final honeypot = _setup(contract: _contract(targetRiskMultiplier: 1.0, isHoneypot: true));
      final normal = _setup(contract: _contract(targetRiskMultiplier: 1.0));
      final outcome = const MinigameOutcome(success: false, timeRatio: 0.0);

      final honeypotRes = ResolutionEngine.resolve(honeypot, outcome);
      final normalRes = ResolutionEngine.resolve(normal, outcome);

      expect(honeypotRes.wantedDelta, greaterThan(normalRes.wantedDelta));
    });
  });

  group('ResolutionEngine.resolve — Clean Up Traces', () {
    test('success reduces wanted instead of paying epts, regardless of speed', () {
      final setup = _setup(
        contract: _contract(
          missionTypeId: ResolutionEngine.cleanUpMissionTypeId,
          eptsReward: 999, // should be ignored entirely for this mission
        ),
      );

      final perfect = ResolutionEngine.resolve(
        setup,
        const MinigameOutcome(success: true, timeRatio: 0.9),
      );
      final slow = ResolutionEngine.resolve(
        setup,
        const MinigameOutcome(success: true, timeRatio: 0.1),
      );

      for (final res in [perfect, slow]) {
        expect(res.result, AttackResultKind.success);
        expect(res.eptsDelta, 0);
        expect(res.wantedDelta, -WantedEffects.cleanUpReduction);
      }
    });

    test('failure on a Clean Up Traces contract behaves like any other failure', () {
      final setup = _setup(
        contract: _contract(missionTypeId: ResolutionEngine.cleanUpMissionTypeId),
      );
      final res = ResolutionEngine.resolve(
        setup,
        const MinigameOutcome(success: false, timeRatio: 0.0),
      );
      expect(res.result, AttackResultKind.fail);
      expect(res.wantedDelta, greaterThan(0));
    });
  });
}
