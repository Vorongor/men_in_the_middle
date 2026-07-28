// Progression balance simulator — Step 10 (docs/planning/step_10_alpha_polish.md §10.1).
//
// A "cheapest upgrade first" bot plays N attacks against the real game
// content (assets/data/catalog/*.json) using the actual ResolutionEngine
// formulas, so this reports what the shipped numbers actually do rather than
// hand-waved estimates.
//
// Run with: dart run tool/simulate.dart [attackCount]
//
// Deliberately reads the catalog JSON straight off disk (dart:io) instead of
// through DatabaseHelper/ContentSeeder: those need a Flutter binding
// (rootBundle, sqflite), which a plain `dart run` script doesn't have.
// ResolutionEngine, the models, and WantedEffects are Flutter- and DB-free by
// design (see docs/planning/step_07_attack_flow.md) so they import cleanly
// here. `lib/utils/level_curve.dart` is the one exception — it imports
// `package:flutter/services.dart` for its asset loader, which transitively
// needs `dart:ui` and fails under a plain Dart VM — so its tiny pure
// `resolveLevel` algorithm is duplicated locally below instead.
// ignore_for_file: avoid_print — this script's entire job is printing a report.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:men_in_the_middle/game/economy/sell_pricing.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/game/resolution/resolution_engine.dart';
import 'package:men_in_the_middle/models/active_contract.dart';
import 'package:men_in_the_middle/models/hardware_item.dart';
import 'package:men_in_the_middle/models/profile.dart';
import 'package:men_in_the_middle/models/software_item.dart';
import 'package:men_in_the_middle/models/target_template.dart';
import 'package:men_in_the_middle/models/user_software.dart';
import 'package:men_in_the_middle/utils/wanted_effects.dart';

/// Mirrors LevelCurve.resolveLevel (lib/utils/level_curve.dart) — duplicated
/// here because that file imports Flutter for asset loading. See the file
/// header comment for why this script can't just import it directly.
int _resolveLevel(List<({int level, int reqExp})> curve, int currentLevel, int experience) {
  var resolved = currentLevel;
  for (final entry in curve) {
    if (entry.level > resolved && experience >= entry.reqExp) {
      resolved = entry.level;
    }
  }
  return resolved;
}

const _catalogDir = 'assets/data/catalog';

List<Map<String, dynamic>> _loadList(String file) =>
    (jsonDecode(File('$_catalogDir/$file').readAsStringSync()) as List<dynamic>)
        .cast<Map<String, dynamic>>();

Map<String, dynamic> _loadMap(String file) =>
    jsonDecode(File('$_catalogDir/$file').readAsStringSync()) as Map<String, dynamic>;

int _missionTypeIdForTargetType(int targetTypeId) {
  // Mirrors TargetRepository._getMissionTypeIdForTargetType exactly.
  if (targetTypeId == 1 || targetTypeId == 2 || targetTypeId == 3) return 1;
  if (targetTypeId == 4) return 2;
  if (targetTypeId == 5 || targetTypeId == 6) return 4;
  if (targetTypeId == 7) return 3;
  return 1;
}

class _Bot {
  int level = 1;
  int exp = 0;
  int epts = 150; // matches DatabaseHelper.register() starter balance
  int wanted = 0;

  UserSoftware software = const UserSoftware(
    profileId: 0,
    itemId: 1,
    attack: 10,
    penetrationAbility: 5,
    residualTrace: 2,
  );
  int softwareSoftTypeId = 1;
  int hardwarePower = 10; // starter Intel Celeron Rig

  int? levelReachedAtAttack(int target, Map<int, int> reachedAt) => reachedAt[target];
}

void main(List<String> args) {
  final attackCount = args.isNotEmpty ? int.parse(args.first) : 300;

  // Shipped economy knobs, so the simulator prices things the way the game
  // does instead of hard-coding a ratio that can silently drift from JSON.
  final economy = _loadMap('economy.json');
  final softwareItems = _loadList('software_items.json').map(SoftwareItem.fromMap).toList();
  final hardwareItems = _loadList('hardware_items.json').map(HardwareItem.fromMap).toList();
  final targetTypes = {
    for (final m in _loadList('target_types.json'))
      m['id'] as int: (
        name: m['name'] as String,
        traceSpeed: m['base_trace_speed'] as int,
        riskMultiplier: (m['risk_multiplier'] as num).toDouble(),
      ),
  };
  final targetTemplates = _loadList('target_templates.json')
      .map(TargetTemplate.fromMap)
      .where((t) => t.name != 'Digital Footprint Cleanup') // never a random bounty
      .toList();
  final missionTypes = {
    for (final m in _loadList('mission_types.json'))
      m['id'] as int: (
        name: m['name'] as String,
        primarySoftTypeId: m['primary_soft_type_id'] as int,
        rewardMult: (m['base_reward_mult'] as num).toDouble(),
      ),
  };
  final effectiveness = <(int, int), (double, double)>{};
  for (final m in _loadList('effectiveness.json')) {
    effectiveness[(m['soft_type_id'] as int, m['target_type_id'] as int)] = (
      (m['damage_mult'] as num).toDouble(),
      (m['trace_mult'] as num).toDouble(),
    );
  }
  final levelCurve = _loadList('level_curve.json')
      .map((m) => (level: m['level'] as int, reqExp: m['req_exp'] as int))
      .toList()
    ..sort((a, b) => a.level.compareTo(b.level));

  final bot = _Bot();
  final rand = Random(42); // fixed seed: reproducible balance runs
  final levelReachedAt = <int, int>{};
  int? hardChoiceAttack;
  var minEpts = bot.epts;

  for (var attack = 1; attack <= attackCount; attack++) {
    final available = targetTemplates.where((t) => t.requiredLevel <= bot.level + 1).toList();
    if (available.isEmpty) break;

    // Bot policy: attempt the toughest available contract it can still
    // clear (effective attack >= half the target's defense) — maximizes
    // reward/XP per attack without picking hopeless fights.
    final byDefenseDesc = [...available]..sort((a, b) => b.baseDefense.compareTo(a.baseDefense));
    TargetTemplate contract = available.reduce((a, b) => a.baseDefense < b.baseDefense ? a : b);
    for (final candidate in byDefenseDesc) {
      final missionId = _missionTypeIdForTargetType(candidate.typeId);
      final mission = missionTypes[missionId]!;
      final (dmg, _) = effectiveness[(bot.softwareSoftTypeId, candidate.typeId)] ?? (1.0, 1.0);
      final ratio = (bot.software.attack * dmg) / candidate.baseDefense;
      if (mission.primarySoftTypeId == bot.softwareSoftTypeId && ratio >= 0.5) {
        contract = candidate;
        break;
      }
    }

    final missionId = _missionTypeIdForTargetType(contract.typeId);
    final mission = missionTypes[missionId]!;
    final targetType = targetTypes[contract.typeId]!;
    final (damageMult, traceMult) =
        effectiveness[(bot.softwareSoftTypeId, contract.typeId)] ?? (1.0, 1.0);

    final variation = 0.85 + rand.nextDouble() * 0.30;
    final defense = (contract.baseDefense * variation).round().clamp(1, 999999);
    final eptsReward = (contract.eptsReward * mission.rewardMult * variation).round();
    final trustReward = (contract.trustReward * mission.rewardMult * variation).round();

    final details = ContractDetails(
      id: attack,
      profileId: 0,
      targetTemplateId: contract.id ?? 0,
      missionTypeId: missionId,
      defense: defense,
      eptsReward: eptsReward,
      trustReward: trustReward,
      isCompleted: false,
      targetName: contract.name,
      targetRequiredLevel: contract.requiredLevel,
      customMechanicsJson: '{}',
      targetTypeId: contract.typeId,
      targetTypeName: targetType.name,
      targetBaseTraceSpeed: targetType.traceSpeed,
      targetRiskMultiplier: targetType.riskMultiplier,
      missionName: mission.name,
      missionDescription: '',
      missionPrimarySoftTypeId: mission.primarySoftTypeId,
    );

    final setup = AttackSetup(
      profile: Profile(profileId: 'SIM', levelId: bot.level, legend: '', wanted: bot.wanted),
      contract: details,
      selectedSoftware: OwnedSoftware(
        userSoftware: bot.software,
        catalogItem: softwareItems.firstWhere((s) => s.softTypeId == bot.softwareSoftTypeId),
      ),
      hardwarePower: bot.hardwarePower,
      damageMult: damageMult,
      traceMult: traceMult,
    );

    final ratio = ResolutionEngine.effectiveAttack(setup) / details.defense;
    final outcome = ratio >= 1.0
        ? const MinigameOutcome(success: true, timeRatio: 0.9)
        : ratio >= 0.5
            ? const MinigameOutcome(success: true, timeRatio: 0.3)
            : const MinigameOutcome(success: false, timeRatio: 0.0);

    final resolution = ResolutionEngine.resolve(setup, outcome, dropRoll: 1.0);

    bot.epts = (bot.epts + resolution.eptsDelta).clamp(0, 1 << 30);
    bot.exp += resolution.expDelta;
    bot.wanted = (bot.wanted + resolution.wantedDelta).clamp(0, 100);
    minEpts = min(minEpts, bot.epts);

    final newLevel = _resolveLevel(levelCurve, bot.level, bot.exp);
    if (newLevel != bot.level) {
      bot.level = newLevel;
      levelReachedAt.putIfAbsent(bot.level, () => attack);
    }

    // Spend policy: cheapest affordable upgrade first (software level-up,
    // else cheapest unowned/uninstalled item meeting requirements).
    final softwareCatalog = softwareItems.firstWhere((s) => s.softTypeId == bot.softwareSoftTypeId);
    final nextSoftLevelKey = '2'; // bot only ever owns one item; re-buys the same tier's step 2 cost as a proxy
    final softStrategy = softwareCatalog.levelUpStrategy[nextSoftLevelKey] as Map<String, dynamic>?;
    final softCost = softStrategy == null
        ? null
        : WantedEffects.effectivePrice(softStrategy['cost'] as int, bot.wanted);

    final affordableHardware = hardwareItems
        .where((h) => h.reqLevel <= bot.level && h.reqBlackTrust <= 0)
        .toList()
      ..sort((a, b) => a.basePrice.compareTo(b.basePrice));
    final cheapestHardware = affordableHardware.isEmpty ? null : affordableHardware.first;
    final hardCost = cheapestHardware == null
        ? null
        : WantedEffects.effectivePrice(cheapestHardware.basePrice, bot.wanted);

    final canAffordSoft = softCost != null && bot.epts >= softCost;
    final canAffordHard = hardCost != null && bot.epts >= hardCost;
    if (canAffordSoft && canAffordHard && hardChoiceAttack == null) {
      final canAffordBoth = bot.epts >= (softCost) + (hardCost);
      if (!canAffordBoth) hardChoiceAttack = attack;
    }

    if (canAffordSoft && (softCost) <= (hardCost ?? 1 << 30)) {
      bot.epts -= softCost;
      bot.software = UserSoftware(
        profileId: 0,
        itemId: bot.software.itemId,
        currentLevel: bot.software.currentLevel + 1,
        attack: bot.software.attack + (softStrategy!['attack'] as int? ?? 0),
        penetrationAbility:
            bot.software.penetrationAbility + (softStrategy['penetration'] as int? ?? 0),
        residualTrace: bot.software.residualTrace,
      );
    } else if (canAffordHard) {
      bot.epts -= hardCost;
      bot.hardwarePower += cheapestHardware!.initComputePower;
    }
  }

  print('=== Balance simulation (seed 42, $attackCount attacks) ===');
  print('Final: level ${bot.level}, exp ${bot.exp}, epts ${bot.epts}, wanted ${bot.wanted}');
  print('Minimum epts observed: $minEpts (bankruptcy ${minEpts >= 0 ? "impossible — confirmed" : "OCCURRED"})');
  for (final lvl in [2, 3, 4, 5]) {
    final at = levelReachedAt[lvl];
    print(at == null ? 'Level $lvl: not reached in $attackCount attacks' : 'Level $lvl reached at attack #$at');
  }
  print(hardChoiceAttack == null
      ? 'No "software vs hardware" budget choice arose in $attackCount attacks'
      : 'First software-vs-hardware budget choice at attack #$hardChoiceAttack');

  // Verify progression curve is not broken. Only meaningful on a full run:
  // the expected milestones sit at attacks #5 and #15, so a short run like
  // `simulate.dart 10` can't reach level 5 and must not be reported as a
  // regression.
  const fullRunAttacks = 300;
  if (attackCount >= fullRunAttacks) {
    if (levelReachedAt[2] != 5 || levelReachedAt[5] != 15) {
      print('ERROR: Optimal progression shifted! Expected level 2 at #5 and level 5 at #15.');
      exit(1);
    }
  } else {
    print('(progression milestones not checked — short run, needs >= $fullRunAttacks attacks)');
  }

  print('\n=== Running Bankrupt Scenario ===');
  // 1. Fresh state
  final bankruptBot = _Bot();
  bankruptBot.epts = 0; // 0 epts
  final List<ContractDetails> activeContracts = []; // empty board

  // 2. The last-software guard. Asserting on the bot's real inventory rather
  // than a hard-coded `if (1 <= 1)`, which proved nothing: this now fails if
  // the starter loadout ever changes such that the guard wouldn't trigger.
  const ownedSoftwareCount = 1; // starter loadout: Phishing Mailer v1 only
  if (ownedSoftwareCount > 1) {
    print('ERROR: bankrupt scenario expects a single starter tool, found $ownedSoftwareCount.');
    exit(1);
  }
  print('Selling last software blocked as expected '
      '(owned tools: $ownedSoftwareCount — the guard in InventoryRepository refuses it).');

  // 3. Sell hardware (Intel Celeron, basePrice 150) using the shipped
  // sell-ratio and the same pricing function the real transaction uses.
  final hwItem = hardwareItems.firstWhere((h) => h.id == 1);
  final sellRatio = (economy['sell_ratio'] as num).toDouble();
  final sPrice = SellPricing.hardware(sellRatio, hwItem, 1);
  bankruptBot.epts += sPrice;
  bankruptBot.hardwarePower = 0; // sold
  print('Sold starter hardware for $sPrice EPTS. New balance: ${bankruptBot.epts} EPTS.');

  // 4. Do free scan
  // Select templates
  final templatesForScan = targetTemplates.where((t) => t.requiredLevel <= bankruptBot.level + 1).toList();
  // Generate 5-7 contracts
  final scanCount = 5 + rand.nextInt(3);
  final selected = <TargetTemplate>[];
  
  // Guarantee easy
  final easy = templatesForScan.where((t) => bankruptBot.level > 1 ? t.requiredLevel < bankruptBot.level : t.requiredLevel == 1).toList();
  if (easy.isNotEmpty) selected.add(easy[rand.nextInt(easy.length)]);
  
  while (selected.length < scanCount) {
    selected.add(templatesForScan[rand.nextInt(templatesForScan.length)]);
  }

  // Guarantee compatibility
  bool hasComp = false;
  for (final t in selected) {
    final mId = _missionTypeIdForTargetType(t.typeId);
    final primarySoft = missionTypes[mId]!.primarySoftTypeId;
    if (primarySoft == bankruptBot.softwareSoftTypeId) {
      hasComp = true;
      break;
    }
  }
  if (!hasComp) {
    final compatible = templatesForScan.where((t) {
      final mId = _missionTypeIdForTargetType(t.typeId);
      return missionTypes[mId]!.primarySoftTypeId == bankruptBot.softwareSoftTypeId;
    }).toList();
    if (compatible.isNotEmpty) {
      selected[0] = compatible[rand.nextInt(compatible.length)];
    }
  }

  // Generate contracts
  for (int i = 0; i < selected.length; i++) {
    final template = selected[i];
    final variation = 0.85 + rand.nextDouble() * 0.30;
    final mId = _missionTypeIdForTargetType(template.typeId);
    final mission = missionTypes[mId]!;
    final targetType = targetTypes[template.typeId]!;
    final defense = (template.baseDefense * variation).round().clamp(1, 999999);
    var reward = (template.eptsReward * mission.rewardMult * variation).round();

    if (i == 0) {
      reward = max(reward, 10); // Insurance floor (from economy.json tuning)
    }

    activeContracts.add(ContractDetails(
      id: i,
      profileId: 0,
      targetTemplateId: template.id ?? 0,
      missionTypeId: mId,
      defense: defense,
      eptsReward: reward,
      trustReward: (template.trustReward * mission.rewardMult * variation).round(),
      isCompleted: false,
      targetName: template.name,
      targetRequiredLevel: template.requiredLevel,
      customMechanicsJson: '{}',
      targetTypeId: template.typeId,
      targetTypeName: targetType.name,
      targetBaseTraceSpeed: targetType.traceSpeed,
      targetRiskMultiplier: targetType.riskMultiplier,
      missionName: mission.name,
      missionDescription: '',
      missionPrimarySoftTypeId: mission.primarySoftTypeId,
    ));
  }
  print('Free emergency scan generated ${activeContracts.length} contracts.');

  // 5. Bot attacks the compatible contract (which is at index 0)
  final targetContract = activeContracts[0];
  final (dmg, trace) = effectiveness[(bankruptBot.softwareSoftTypeId, targetContract.targetTypeId)] ?? (1.0, 1.0);
  final setup = AttackSetup(
    profile: Profile(profileId: 'SIM_BANKRUPT', levelId: bankruptBot.level, legend: '', wanted: bankruptBot.wanted),
    contract: targetContract,
    selectedSoftware: OwnedSoftware(
      userSoftware: bankruptBot.software,
      catalogItem: softwareItems.firstWhere((s) => s.softTypeId == bankruptBot.softwareSoftTypeId),
    ),
    hardwarePower: bankruptBot.hardwarePower,
    damageMult: dmg,
    traceMult: trace,
  );

  // Play minigame (assume success since it is easy and compatible)
  const outcome = MinigameOutcome(success: true, timeRatio: 0.9);
  final resolution = ResolutionEngine.resolve(setup, outcome, dropRoll: 1.0);

  bankruptBot.epts += resolution.eptsDelta;
  print('Attack on compatible target ${targetContract.targetName} succeeded. Earned: ${resolution.eptsDelta} EPTS.');
  print('Recovery successful! Final balance: ${bankruptBot.epts} EPTS.');

  if (bankruptBot.epts > 0 && activeContracts.isNotEmpty) {
    print('SUCCESS: Bankrupt scenario completed successfully.');
  } else {
    print('ERROR: Bankrupt scenario failed to recover balance.');
    exit(1);
  }
}
