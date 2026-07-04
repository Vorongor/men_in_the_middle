import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/resolution/attack_models.dart';
import '../game/resolution/resolution_engine.dart';
import '../models/active_contract.dart';
import '../models/user_software.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../repos/target_repository.dart';
import '../state/attack_session.dart';
import '../state/player_session.dart';
import '../utils/async_value_ext.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../utils/soft_type_names.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/onboarding_banner.dart';

typedef _PrepData = (
  ContractDetails?,
  List<OwnedSoftware>,
  Map<(int, int), (double, double)>,
);

class AttackPrepScreen extends ConsumerStatefulWidget {
  const AttackPrepScreen({super.key});

  @override
  ConsumerState<AttackPrepScreen> createState() => _AttackPrepScreenState();
}

class _AttackPrepScreenState extends ConsumerState<AttackPrepScreen> {
  late Future<_PrepData> _loadFuture;
  int? _selectedUserSoftwareId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load() {
    final args = ModalRoute.of(context)!.settings.arguments as AttackPrepArgs?;
    final profile = ref.read(playerSessionProvider).valueOrNull?.profile;

    if (args == null || profile?.id == null) {
      _loadFuture = Future.value((
        null,
        const <OwnedSoftware>[],
        const <(int, int), (double, double)>{},
      ));
      return;
    }

    final targetRepo = ref.read(targetRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);
    final catalogRepo = ref.read(catalogRepositoryProvider);

    _loadFuture =
        Future.wait([
          targetRepo.fetchContractDetails(args.contractId),
          inventoryRepo.fetchOwnedSoftware(profile!.id!),
          catalogRepo.effectivenessMatrix(),
        ]).then(
          (res) => (
            res[0] as ContractDetails?,
            res[1] as List<OwnedSoftware>,
            res[2] as Map<(int, int), (double, double)>,
          ),
        );
  }

  Color _multColor(double mult) {
    if (mult >= 1.5) return Colors.greenAccent;
    if (mult <= 0.5) return Colors.redAccent;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(playerSessionProvider).valueOrNull?.profile;
    if (profile == null) {
      return const GameScaffold(
        screenNum: '7.1',
        screenName: 'ATTACK PREPARATION',
        body: Center(child: Text('Not authenticated')),
      );
    }

    return FutureBuilder<_PrepData>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GameScaffold(
            screenNum: '7.1',
            screenName: 'ATTACK PREPARATION',
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        final data = snapshot.data;
        if (snapshot.hasError || data == null || data.$1 == null) {
          return const GameScaffold(
            screenNum: '7.1',
            screenName: 'ATTACK PREPARATION',
            body: Center(child: Text('Failed to load contract')),
          );
        }

        final contract = data.$1!;
        final ownedSoftware = data.$2;
        final matrix = data.$3;

        OwnedSoftware? selected;
        for (final s in ownedSoftware) {
          if (s.userSoftware.id == _selectedUserSoftwareId) {
            selected = s;
            break;
          }
        }

        AttackSetup? setup;
        if (selected != null) {
          final (damageMult, traceMult) =
              matrix[(
                selected.catalogItem.softTypeId,
                contract.targetTypeId,
              )] ??
              (1.0, 1.0);
          setup = AttackSetup(
            profile: profile,
            contract: contract,
            selectedSoftware: selected,
            hardwarePower: profile.hardwarePower,
            damageMult: damageMult,
            traceMult: traceMult,
          );
        }

        final underpowered = profile.hardwarePower < contract.defense / 2;

        return GameScaffold(
          screenNum: '7.1',
          screenName: 'ATTACK PREPARATION',
          body: Stack(
            children: [
              _prepBody(context, contract, ownedSoftware, underpowered, setup),
              const OnboardingTip(
                tipKey: 'attack_prep',
                message:
                    'Pick software that matches this mission\'s type — '
                    'mismatched tools barely scratch the target.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _prepBody(
    BuildContext context,
    ContractDetails contract,
    List<OwnedSoftware> ownedSoftware,
    bool underpowered,
    AttackSetup? setup,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPERATION BRIEF',
            style: GoogleFonts.cinzel(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          const Divider(color: Colors.white12, height: 16),
          _PrepRow('Target', contract.targetName),
          _PrepRow('Mission', contract.missionName),
          _PrepRow('Defense', '${contract.defense} FLOPS'),
          _PrepRow('Reward', '${contract.eptsReward} EPTS'),
          if (setup != null) ...[
            _PrepRow(
              'Est. Time Budget',
              '${ResolutionEngine.timeBudgetSeconds(setup)}s',
            ),
            _PrepRow(
              'Damage Mult.',
              '\u00d7${setup.damageMult.toStringAsFixed(1)}',
              valueColor: _multColor(setup.damageMult),
              valueBold: true,
            ),
          ],
          if (underpowered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF241C0C),
                border: Border.all(color: const Color(0xFF4A3A1A)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.amberAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hardware power low for this target — expect a shorter time budget.',
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'SELECT SOFTWARE',
            style: GoogleFonts.cinzel(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          const Divider(color: Colors.white12, height: 16),
          if (ownedSoftware.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No software owned. Visit the Store first.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: ownedSoftware.map((s) {
                  final compatible =
                      s.catalogItem.softTypeId ==
                      contract.missionPrimarySoftTypeId;
                  final isSelected =
                      s.userSoftware.id == _selectedUserSoftwareId;
                  return _SoftwareRow(
                    name: s.catalogItem.name,
                    typeName: softwareTypeName(s.catalogItem.softTypeId),
                    attack: s.userSoftware.attack,
                    penetration: s.userSoftware.penetrationAbility,
                    compatible: compatible,
                    selected: isSelected,
                    onTap: compatible
                        ? () => setState(
                            () => _selectedUserSoftwareId = s.userSoftware.id,
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: setup == null
                  ? null
                  : () {
                      ref.read(attackSessionProvider.notifier).start(setup);
                      Navigator.pushNamed(
                        context,
                        Routes.attackPlay,
                        arguments: AttackPrepArgs(contractId: contract.id),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                disabledForegroundColor: Colors.white24,
                side: BorderSide(
                  color: setup == null
                      ? const Color(0xFF222222)
                      : const Color(0xFF3A1A1A),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'LAUNCH ATTACK',
                style: GoogleFonts.cinzel(fontSize: 12, letterSpacing: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PrepRow extends StatelessWidget {
  const _PrepRow(
    this.label,
    this.value, {
    this.valueColor,
    this.valueBold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Label: Flexible so it can shrink on very narrow windows instead
          // of hard-overflowing.
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
          // Value: Expanded so it takes the remaining space and clips with
          // ellipsis instead of overflowing the Row.
          Expanded(
            child: Text(
              value,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight:
                    valueBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftwareRow extends StatelessWidget {
  const _SoftwareRow({
    required this.name,
    required this.typeName,
    required this.attack,
    required this.penetration,
    required this.compatible,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String typeName;
  final int attack;
  final int penetration;
  final bool compatible;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = compatible ? Colors.white : Colors.white24;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0C160C) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: compatible ? Colors.greenAccent : Colors.white12,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: labelColor, fontSize: 13)),
                  Text(
                    '$typeName · ATK $attack · PEN $penetration',
                    style: TextStyle(
                      color: compatible ? Colors.white38 : Colors.white12,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!compatible)
              const Text(
                'INCOMPATIBLE',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
