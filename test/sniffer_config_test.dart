// Pure unit tests: no Flutter binding, no Flame game loop, no DB — matches
// the discipline established in resolution_engine_test.dart. SnifferConfig
// is just a function of an AttackSetup.
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/game/resolution/resolution_engine.dart';
import 'package:men_in_the_middle/game/sniffer/sniffer_config.dart';
import 'package:men_in_the_middle/models/active_contract.dart';
import 'package:men_in_the_middle/models/profile.dart';
import 'package:men_in_the_middle/models/software_item.dart';
import 'package:men_in_the_middle/models/user_software.dart';

Profile _profile() => const Profile(
      id: 1,
      profileId: 'AB12345',
      levelId: 1,
      hardwarePower: 20,
      legend: 'test',
    );

ContractDetails _contract({int defense = 100}) => ContractDetails(
      id: 1,
      profileId: 1,
      targetTemplateId: 1,
      missionTypeId: 1,
      defense: defense,
      eptsReward: 300,
      trustReward: 10,
      isCompleted: false,
      targetName: 'Test Node',
      targetRequiredLevel: 1,
      customMechanicsJson: '{}',
      targetTypeId: 3,
      targetTypeName: 'Corporate Employees',
      targetBaseTraceSpeed: 10,
      targetRiskMultiplier: 1.0,
      missionName: 'Data Theft',
      missionDescription: 'desc',
      missionPrimarySoftTypeId: 1,
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
  ContractDetails? contract,
}) =>
    AttackSetup(
      profile: _profile(),
      contract: contract ?? _contract(),
      selectedSoftware: _software(attack: attack, penetration: penetration),
      hardwarePower: hardwarePower,
      damageMult: damageMult,
      traceMult: 1.0,
    );

void main() {
  group('SnifferConfig.fromSetup — delegation', () {
    test('timeBudgetSeconds matches ResolutionEngine exactly', () {
      final setup = _setup();
      final config = SnifferConfig.fromSetup(setup);
      expect(config.timeBudgetSeconds, ResolutionEngine.timeBudgetSeconds(setup));
    });
  });

  group('SnifferConfig.fromSetup — software strength scaling', () {
    test('stronger software gives a wider paddle and more allowed red hits', () {
      final weak = SnifferConfig.fromSetup(_setup(attack: 5, penetration: 5));
      final strong = SnifferConfig.fromSetup(_setup(attack: 100, penetration: 80));

      expect(strong.paddleWidthFactor, greaterThan(weak.paddleWidthFactor));
      expect(strong.allowedRedHits, greaterThanOrEqualTo(weak.allowedRedHits));
    });

    test('higher penetration slows packets down and reduces the red ratio', () {
      final lowPen = SnifferConfig.fromSetup(_setup(penetration: 0));
      final highPen = SnifferConfig.fromSetup(_setup(penetration: 100));

      expect(highPen.fallSpeed, lessThan(lowPen.fallSpeed));
      expect(highPen.redRatio, lessThanOrEqualTo(lowPen.redRatio));
    });
  });

  group('SnifferConfig.fromSetup — target difficulty scaling', () {
    test('tougher targets require more catches and drop packets faster', () {
      final easy = SnifferConfig.fromSetup(_setup(contract: _contract(defense: 30)));
      final hard = SnifferConfig.fromSetup(_setup(contract: _contract(defense: 900)));

      expect(hard.targetCatches, greaterThan(easy.targetCatches));
      expect(hard.fallSpeed, greaterThan(easy.fallSpeed));
    });

    test('chameleon packets only appear once defense reaches the MEDIUM threshold', () {
      final easy = SnifferConfig.fromSetup(_setup(contract: _contract(defense: 60)));
      final medium = SnifferConfig.fromSetup(_setup(contract: _contract(defense: 150)));

      expect(easy.chameleonChance, 0.0);
      expect(medium.chameleonChance, greaterThan(0.0));
    });
  });

  group('SnifferConfig.fromSetup — bounds', () {
    test('every field stays within its documented clamp range for extreme inputs', () {
      final extreme = SnifferConfig.fromSetup(
        _setup(attack: 10000, penetration: 10000, contract: _contract(defense: 100000)),
      );

      expect(extreme.paddleWidthFactor, inInclusiveRange(0.8, 2.2));
      expect(extreme.allowedRedHits, inInclusiveRange(0, 3));
      expect(extreme.fallSpeed, inInclusiveRange(60, 420));
      expect(extreme.redRatio, inInclusiveRange(0.15, 0.32));
      expect(extreme.targetCatches, inInclusiveRange(6, 20));
      expect(extreme.spawnIntervalSeconds, inInclusiveRange(0.35, 0.85));

      final feeble = SnifferConfig.fromSetup(
        _setup(attack: 0, penetration: 0, contract: _contract(defense: 1)),
      );
      expect(feeble.paddleWidthFactor, inInclusiveRange(0.8, 2.2));
      expect(feeble.allowedRedHits, inInclusiveRange(0, 3));
      expect(feeble.fallSpeed, inInclusiveRange(60, 420));
      expect(feeble.redRatio, inInclusiveRange(0.15, 0.32));
      expect(feeble.targetCatches, inInclusiveRange(6, 20));
      expect(feeble.spawnIntervalSeconds, inInclusiveRange(0.35, 0.85));
    });
  });
}
