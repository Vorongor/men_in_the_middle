import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/resolution/attack_models.dart';
import '../game/resolution/resolution_engine.dart';
import '../models/active_contract.dart';
import '../models/user_software.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../repos/target_repository.dart';
import '../state/attack_session.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
        ]).then((res) {
          final contract = res[0] as ContractDetails?;
          final owned = res[1] as List<OwnedSoftware>;
          if (_selectedUserSoftwareId == null && owned.isNotEmpty && contract != null) {
            final compatibleSoft = owned.where(
              (s) => s.catalogItem.softTypeId == contract.missionPrimarySoftTypeId,
            );
            if (compatibleSoft.isNotEmpty) {
              _selectedUserSoftwareId = compatibleSoft.first.userSoftware.id;
            } else {
              _selectedUserSoftwareId = owned.first.userSoftware.id;
            }
          }
          return (
            contract,
            owned,
            res[2] as Map<(int, int), (double, double)>,
          );
        });
  }

  Color _multColor(double mult) {
    if (mult >= 1.5) return AppColors.primary;
    if (mult <= 0.5) return AppColors.alert;
    return AppColors.textHigh;
  }

  Color _verdictColor(double ratio) {
    if (ratio >= 1.0) return AppColors.primary;
    if (ratio >= 0.5) return AppColors.warning;
    return AppColors.alert;
  }

  Widget _buildVerdictRow(AttackSetup setup) {
    final ratio = ResolutionEngine.powerRatio(setup);
    final isMismatch = setup.damageMult <= 0.2;
    
    String verdict;
    Color color;
    if (ratio >= 1.0) {
      verdict = 'STRONG';
      color = AppColors.primary;
    } else if (ratio >= 0.5) {
      verdict = 'RISKY';
      color = AppColors.warning;
    } else {
      verdict = isMismatch ? 'SUICIDE (tool mismatch)' : 'SUICIDE';
      color = AppColors.alert;
    }

    return _PrepRow(
      'Verdict',
      verdict,
      valueColor: color,
      valueBold: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(playerSessionProvider).valueOrNull?.profile;
    if (profile == null) {
      return GameScaffold(
        screenNum: '7.1',
        screenName: 'ATTACK PREPARATION',
        body: Center(
          child: Text(
            'Not authenticated',
            style: AppTextStyles.body(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return FutureBuilder<_PrepData>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GameScaffold(
            screenNum: '7.1',
            screenName: 'ATTACK PREPARATION',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (snapshot.hasError || data == null || data.$1 == null) {
          return GameScaffold(
            screenNum: '7.1',
            screenName: 'ATTACK PREPARATION',
            body: Center(
              child: Text(
                'Failed to load contract',
                style: AppTextStyles.body(color: AppColors.alert),
              ),
            ),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPERATION BRIEF',
              style: AppTextStyles.sectionLabel(color: AppColors.textMuted).copyWith(
                fontSize: 11,
              ),
            ),
            const Divider(height: 16),
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
              const SizedBox(height: 20),
              Text(
                'ATTACK FORECAST',
                style: AppTextStyles.sectionLabel(color: AppColors.textMuted).copyWith(
                  fontSize: 11,
                ),
              ),
              const Divider(height: 16),
              _PrepRow('Effective Attack', '${ResolutionEngine.effectiveAttack(setup)} FLOPS'),
              _PrepRow('Target Defense', '${contract.defense} FLOPS'),
              _PrepRow(
                'Power Ratio',
                '${ResolutionEngine.powerRatio(setup).toStringAsFixed(2)}x',
                valueColor: _verdictColor(ResolutionEngine.powerRatio(setup)),
                valueBold: true,
              ),
              _PrepRow(
                'Trace Risk',
                ResolutionEngine.traceRisk(setup).toStringAsFixed(2),
                valueColor: AppColors.alert,
              ),
              _buildVerdictRow(setup),
            ],
            if (underpowered) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hardware power low for this target — expect a shorter time budget.',
                        style: AppTextStyles.caption(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'SELECT SOFTWARE',
              style: AppTextStyles.sectionLabel(color: AppColors.textMuted).copyWith(
                fontSize: 11,
              ),
            ),
            const Divider(height: 16),
            if (ownedSoftware.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No software owned. Visit the Store first.',
                  style: AppTextStyles.body(color: AppColors.textMuted),
                ),
              )
            else
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    onTap: () => setState(
                          () => _selectedUserSoftwareId = s.userSoftware.id,
                        ),
                  );
                }).toList(),
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
                  foregroundColor: AppColors.alert,
                  disabledForegroundColor: AppColors.iconLow,
                  side: BorderSide(
                    color: setup == null
                        ? AppColors.border
                        : AppColors.alert,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'LAUNCH ATTACK',
                  style: AppTextStyles.button(color: AppColors.alert).copyWith(fontSize: 12, letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
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
                style: AppTextStyles.body(color: AppColors.textMuted),
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
              style: AppTextStyles.dataMono(color: valueColor ?? AppColors.text).copyWith(
                fontWeight:
                    valueBold ? FontWeight.bold : FontWeight.normal,
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
    final labelColor = compatible ? AppColors.text : AppColors.iconLow;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSuccess : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: compatible ? AppColors.primary : AppColors.iconLow,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.body(color: labelColor)),
                  Text(
                    '$typeName · ATK $attack · PEN $penetration',
                    style: AppTextStyles.caption(
                      color: compatible ? AppColors.textMuted : AppColors.iconLow,
                    ),
                  ),
                ],
              ),
            ),
            if (!compatible)
              Text(
                'INCOMPATIBLE',
                style: AppTextStyles.caption(color: AppColors.iconLow),
              ),
          ],
        ),
      ),
    );
  }
}
