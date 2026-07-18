import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/active_contract.dart';
import '../models/user_software.dart';
import '../repos/inventory_repository.dart';
import '../repos/target_repository.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/async_value_ext.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../utils/soft_type_names.dart';
import '../widgets/game_scaffold.dart';

class TargetDetailScreen extends ConsumerStatefulWidget {
  const TargetDetailScreen({super.key});

  @override
  ConsumerState<TargetDetailScreen> createState() => _TargetDetailScreenState();
}

class _TargetDetailScreenState extends ConsumerState<TargetDetailScreen> {
  late Future<(ContractDetails?, List<OwnedSoftware>)> _loadFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    final args = ModalRoute.of(context)!.settings.arguments as TargetDetailArgs?;
    final profile = ref.read(playerSessionProvider).valueOrNull?.profile;

    if (args != null && profile != null) {
      final targetRepo = ref.read(targetRepositoryProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      setState(() {
        _loadFuture = Future.wait([
          targetRepo.fetchContractDetails(args.contractId),
          inventoryRepo.fetchOwnedSoftware(profile.id!),
        ]).then((res) => (res[0] as ContractDetails?, res[1] as List<OwnedSoftware>));
      });
    } else {
      setState(() {
        _loadFuture = Future.value((null, <OwnedSoftware>[]));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as TargetDetailArgs?;
    if (args == null) {
      return GameScaffold(
        screenNum: '5.2',
        screenName: 'TARGET DETAIL',
        body: Center(
          child: Text(
            'Invalid route arguments',
            style: AppTextStyles.body(color: AppColors.alert),
          ),
        ),
      );
    }

    final profile = ref.watch(playerSessionProvider).valueOrNull?.profile;
    if (profile == null) {
      return GameScaffold(
        screenNum: '5.2',
        screenName: 'TARGET DETAIL',
        body: Center(
          child: Text(
            'Not authenticated',
            style: AppTextStyles.body(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return FutureBuilder<(ContractDetails?, List<OwnedSoftware>)>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GameScaffold(
            screenNum: '5.2',
            screenName: 'TARGET DETAIL',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.$1 == null) {
          return GameScaffold(
            screenNum: '5.2',
            screenName: 'TARGET DETAIL',
            body: Center(
              child: Text(
                'Failed to load target details',
                style: AppTextStyles.body(color: AppColors.alert),
              ),
            ),
          );
        }

        final (contract, ownedSoftware) = snapshot.data!;
        final c = contract!;

        // Check if player owns any software matching the recommended primary type of the mission
        final hasRecommendedSoft = ownedSoftware.any((s) => s.catalogItem.softTypeId == c.missionPrimarySoftTypeId);
        final levelLocked = profile.levelId < c.targetRequiredLevel;

        String buttonText = 'INITIATE ATTACK PROTOCOL';
        if (levelLocked) {
          buttonText = 'LOCKED (LEVEL ${c.targetRequiredLevel} REQUIRED)';
        }

        return GameScaffold(
          screenNum: '5.2',
          screenName: 'TARGET DETAIL',
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSuccess,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSuccess),
                      ),
                      child: const Icon(Icons.radar, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.targetName,
                            style: AppTextStyles.dataMono(color: AppColors.text).copyWith(fontSize: 16),
                          ),
                          Text(
                            'NODE ID: #${c.id.toString().padLeft(4, '0')}  ·  ${c.targetTypeName.toUpperCase()}',
                            style: AppTextStyles.caption(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                Text(
                  'MISSION CLASSIFICATION',
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  c.missionName.toUpperCase(),
                  style: AppTextStyles.dataMono(color: AppColors.primary).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  c.missionDescription,
                  style: AppTextStyles.body(color: AppColors.textHigh).copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),

                Text(
                  'TARGET PROFILE SPECTRAL PARAMETERS',
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _DetailStatRow(label: 'Node Security/Defense', value: '${c.defense} FLOPS'),
                _DetailStatRow(label: 'Trace Tracker Speed', value: '${c.targetBaseTraceSpeed} dB/s'),
                _DetailStatRow(label: 'Security Risk Multiplier', value: 'x${c.targetRiskMultiplier.toStringAsFixed(1)}'),
                _DetailStatRow(label: 'Reward Crypto Bounty', value: '${c.eptsReward} EPTS', highlight: true),
                _DetailStatRow(label: 'Reputation Bounty', value: '+${c.trustReward} Trust', highlight: true),
                _DetailStatRow(
                  label: 'Required Clearance',
                  value: 'LEVEL ${c.targetRequiredLevel}',
                  warning: levelLocked,
                ),

                const SizedBox(height: 20),
                Text(
                  'RECOMMENDED ATTACK WEAPONRY',
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasRecommendedSoft ? Icons.check_circle : Icons.warning_amber,
                        color: hasRecommendedSoft ? AppColors.primary : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${softwareTypeName(c.missionPrimarySoftTypeId).toUpperCase()} UTILITY',
                              style: AppTextStyles.dataMono(color: AppColors.text),
                            ),
                            Text(
                              'Effectiveness: +100% Damage (x2 Mult) against node structure.',
                              style: AppTextStyles.caption(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        hasRecommendedSoft ? 'READY' : 'STORE LACK',
                        style: AppTextStyles.caption(
                          color: hasRecommendedSoft ? AppColors.primary : AppColors.warning,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: levelLocked
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              Routes.attackPrep,
                              arguments: AttackPrepArgs(contractId: c.id),
                            ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.iconLow,
                      side: BorderSide(
                        color: levelLocked ? AppColors.border : AppColors.primary,
                      ),
                      backgroundColor: levelLocked ? Colors.transparent : AppColors.surfaceSuccess,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: Text(
                      buttonText,
                      style: AppTextStyles.button(
                        color: levelLocked ? AppColors.iconLow : AppColors.primary,
                      ).copyWith(fontSize: 13, letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailStatRow extends StatelessWidget {
  const _DetailStatRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    Color valColor = AppColors.textHigh;
    if (highlight) {
      valColor = AppColors.primary;
    } else if (warning) {
      valColor = AppColors.alert;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.dataMono(color: valColor),
          ),
        ],
      ),
    );
  }
}
