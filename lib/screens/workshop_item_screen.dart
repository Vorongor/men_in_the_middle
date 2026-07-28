import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/economy_tuning.dart';
import '../models/hardware_item.dart';
import '../models/software_item.dart';
import '../models/user_hardware.dart';
import '../models/user_software.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../services/audio_service.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_logger.dart';
import '../utils/async_value_ext.dart';
import '../utils/constants.dart';
import '../utils/route_args.dart';
import '../widgets/app_snack.dart';
import '../widgets/game_scaffold.dart';

class WorkshopItemData {
  final dynamic match; // OwnedSoftware or OwnedHardware
  final int totalOwned;

  const WorkshopItemData({required this.match, required this.totalOwned});
}

final workshopItemDataProvider = FutureProvider.family<WorkshopItemData, WorkshopItemArgs>((ref, args) async {
  final profile = ref.watch(playerSessionProvider).valueOrNull?.profile;
  if (profile == null) throw Exception('Not authenticated');
  final repo = ref.watch(inventoryRepositoryProvider);
  if (args.itemType == 'software') {
    final list = await repo.fetchOwnedSoftware(profile.id!);
    final match = list.firstWhere((o) => o.userSoftware.id == args.id);
    return WorkshopItemData(match: match, totalOwned: list.length);
  } else {
    final list = await repo.fetchOwnedHardware(profile.id!);
    final match = list.firstWhere((o) => o.userHardware.id == args.id);
    return WorkshopItemData(match: match, totalOwned: list.length);
  }
});

class WorkshopItemScreen extends ConsumerStatefulWidget {
  const WorkshopItemScreen({super.key});

  @override
  ConsumerState<WorkshopItemScreen> createState() => _WorkshopItemScreenState();
}

class _WorkshopItemScreenState extends ConsumerState<WorkshopItemScreen> {
  static final _log = AppLogger.of('WorkshopItemScreen');

  bool _isUpgrading = false;
  bool _isSelling = false;

  Future<void> _handleUpgrade(int profileId, String type, int id) async {
    setState(() => _isUpgrading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (type == 'software') {
        await repo.upgradeSoftware(profileId, id);
      } else {
        await repo.upgradeHardware(profileId, id);
      }

      // Refresh player session
      await ref.read(playerSessionProvider.notifier).refresh();
      unawaited(AudioService.instance.playSfx(AppAudio.sfxUpgrade));

      // Invalidate provider to trigger UI redraw on spot
      final args = WorkshopItemArgs(itemType: type, id: id);
      ref.invalidate(workshopItemDataProvider(args));

      if (mounted) {
        showAppSnack(
          context,
          'UPGRADE COMPLETED SUCCESSFULLY',
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      _log.warning('Upgrade of $type item #$id failed', e);
      if (mounted) {
        showAppSnack(
          context,
          'UPGRADE FAILED: $e',
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpgrading = false);
      }
    }
  }

  Future<void> _handleSell(int profileId, String type, int id) async {
    setState(() => _isSelling = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      int earnedAmount = 0;
      if (type == 'software') {
        earnedAmount = await repo.sellSoftware(profileId, id);
      } else {
        earnedAmount = await repo.sellHardware(profileId, id);
      }

      await ref.read(playerSessionProvider.notifier).refresh();
      unawaited(AudioService.instance.playSfx(AppAudio.sfxUpgrade));

      if (mounted) {
        showAppSnack(
          context,
          'MODULE SOLD SUCCESSFULLY (+$earnedAmount EPTS)',
          kind: AppSnackKind.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _log.warning('Sell of $type item #$id failed', e);
      if (mounted) {
        showAppSnack(
          context,
          'SELL FAILED: $e',
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelling = false);
      }
    }
  }

  void _showSellConfirmation(BuildContext context, int profileId, String type, int id, int sellPrice, bool isLastHardware) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text(
          'CONFIRM TRANSACTION',
          style: AppTextStyles.dataMono(color: AppColors.text).copyWith(fontSize: 16),
        ),
        content: Text(
          isLastHardware
              ? 'WARNING: This is your last hardware module. Selling it will reduce your compute power to 0, which severely limits your attack capabilities. Are you sure you want to sell it for $sellPrice EPTS?'
              : 'Are you sure you want to sell this module for $sellPrice EPTS?',
          style: AppTextStyles.body(color: AppColors.textHigh),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTextStyles.button(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSell(profileId, type, id);
            },
            child: Text('SELL', style: AppTextStyles.button(color: AppColors.alert)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as WorkshopItemArgs?;
    if (args == null) {
      return const GameScaffold(
        screenNum: '9.2',
        screenName: 'WORKSHOP ITEM',
        body: Center(child: Text('Invalid arguments')),
      );
    }

    final profile = ref.watch(playerSessionProvider).valueOrNull?.profile;
    if (profile == null) {
      return const GameScaffold(
        screenNum: '9.2',
        screenName: 'WORKSHOP ITEM',
        body: Center(child: Text('Not authenticated')),
      );
    }

    final tuningAsync = ref.watch(economyTuningProvider);
    final tuning = tuningAsync.valueOrNull ?? EconomyTuning.defaults;

    final itemAsync = ref.watch(workshopItemDataProvider(args));

    return itemAsync.when(
      loading: () => const GameScaffold(
        screenNum: '9.2',
        screenName: 'WORKSHOP ITEM',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => GameScaffold(
        screenNum: '9.2',
        screenName: 'WORKSHOP ITEM',
        body: Center(
          child: Text('Error: $err', style: AppTextStyles.body(color: AppColors.alert)),
        ),
      ),
      data: (data) {
        if (args.itemType == 'software') {
          return _buildSoftwareUpgrade(profile.id!, profile.eptsBalance, data.match as OwnedSoftware, data.totalOwned, tuning);
        } else {
          return _buildHardwareUpgrade(profile.id!, profile.eptsBalance, data.match as OwnedHardware, data.totalOwned, tuning);
        }
      },
    );
  }

  Widget _buildSoftwareUpgrade(int profileId, int balance, OwnedSoftware o, int totalOwned, EconomyTuning tuning) {
    final us = o.userSoftware;
    final SoftwareItem cat = o.catalogItem;
    
    final currentLvl = us.currentLevel;
    final maxLvl = cat.initMaxLevel;
    final isMax = currentLvl >= maxLvl;

    int cost = 0;
    int attackBonus = 0;
    int penetrationBonus = 0;

    if (!isMax) {
      final nextLvl = currentLvl + 1;
      final step = cat.levelUpStrategy[nextLvl.toString()] as Map<String, dynamic>?;
      if (step != null) {
        cost = step['cost'] as int;
        attackBonus = step['attack'] as int? ?? 0;
        penetrationBonus = step['penetration'] as int? ?? 0;
      }
    }

    final isAffordable = balance >= cost;
    final canUpgrade = !isMax && isAffordable && !_isUpgrading && !_isSelling;

    // Same function the sell transaction uses, so the label, the confirmation
    // dialog and the payout can never disagree.
    final sellPrice = InventoryRepository.softwareSellPrice(tuning, cat, currentLvl);

    String buttonText = 'UPGRADE · $cost EPTS';
    if (isMax) {
      buttonText = 'MAX LEVEL';
    } else if (!isAffordable) {
      buttonText = 'NO FUNDS';
    } else if (_isUpgrading) {
      buttonText = 'COMPILING...';
    }

    return GameScaffold(
      screenNum: '9.2',
      screenName: 'WORKSHOP SOFTWARE',
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSuccess,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderSuccess),
                  ),
                  child: const Icon(Icons.terminal, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: AppTextStyles.dataMono(color: AppColors.text).copyWith(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'SOFTWARE  ·  LEVEL $currentLvl/$maxLvl',
                        style: AppTextStyles.caption(color: AppColors.warning).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              cat.description,
              style: AppTextStyles.body(color: AppColors.textHigh).copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            Text(
              'PERFORMANCE CHARACTERISTICS',
              style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _UpgradeStatRow(
              label: 'Attack Power',
              current: '${us.attack}',
              next: isMax ? null : '${us.attack + attackBonus}',
              delta: isMax ? null : '+$attackBonus',
            ),
            _UpgradeStatRow(
              label: 'Penetration Ability',
              current: '${us.penetrationAbility}',
              next: isMax ? null : '${us.penetrationAbility + penetrationBonus}',
              delta: isMax ? null : '+$penetrationBonus',
            ),
            _UpgradeStatRow(
              label: 'Trace Emission',
              current: '${us.residualTrace}',
              next: null,
              delta: null,
            ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSelling || _isUpgrading
                        ? null
                        : () {
                            if (totalOwned <= 1) {
                              showAppSnack(
                                context,
                                'CANNOT SELL: You must keep at least one software tool.',
                                kind: AppSnackKind.error,
                              );
                              return;
                            }
                            _showSellConfirmation(context, profileId, 'software', us.id!, sellPrice, false);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alert,
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.alert.withValues(alpha: 0.3)),
                      backgroundColor: AppColors.surfaceError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      'SELL · +$sellPrice',
                      style: AppTextStyles.button(color: AppColors.alert).copyWith(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canUpgrade ? () => _handleUpgrade(profileId, 'software', us.id!) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(
                        color: canUpgrade ? AppColors.primary : AppColors.border,
                      ),
                      backgroundColor: canUpgrade ? AppColors.surfaceSuccess : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: AppTextStyles.button(
                        color: canUpgrade ? AppColors.primary : AppColors.textMuted,
                      ).copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareUpgrade(int profileId, int balance, OwnedHardware o, int totalOwned, EconomyTuning tuning) {
    final uh = o.userHardware;
    final HardwareItem cat = o.catalogItem;

    final currentLvl = uh.currentLevel;
    const maxLvl = 5;
    final isMax = currentLvl >= maxLvl;

    int cost = 0;
    int powerBonus = 0;

    if (!isMax) {
      cost = (cat.basePrice * 0.6 * currentLvl).round();
      powerBonus = (cat.initComputePower * 0.25).round();
    }

    final isAffordable = balance >= cost;
    final canUpgrade = !isMax && isAffordable && !_isUpgrading && !_isSelling;

    // Shared with the sell transaction — see softwareSellPrice above.
    final sellPrice = InventoryRepository.hardwareSellPrice(tuning, cat, currentLvl);

    String buttonText = 'UPGRADE · $cost EPTS';
    if (isMax) {
      buttonText = 'MAX LEVEL';
    } else if (!isAffordable) {
      buttonText = 'NO FUNDS';
    } else if (_isUpgrading) {
      buttonText = 'INSTALLING...';
    }

    return GameScaffold(
      screenNum: '9.2',
      screenName: 'WORKSHOP HARDWARE',
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSuccess,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderSuccess),
                  ),
                  child: const Icon(Icons.dns, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: AppTextStyles.dataMono(color: AppColors.text).copyWith(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'HARDWARE MODULE  ·  LEVEL $currentLvl/$maxLvl',
                        style: AppTextStyles.caption(color: AppColors.warning).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              cat.description,
              style: AppTextStyles.body(color: AppColors.textHigh).copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(
              'PERFORMANCE CHARACTERISTICS',
              style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _UpgradeStatRow(
              label: 'Compute Power',
              current: '${uh.computePower} FLOPS',
              next: isMax ? null : '${uh.computePower + powerBonus} FLOPS',
              delta: isMax ? null : '+$powerBonus',
            ),
            _UpgradeStatRow(
              label: 'Power Draw',
              current: '${uh.powerDraw} W',
              next: null,
              delta: null,
            ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSelling || _isUpgrading
                        ? null
                        : () => _showSellConfirmation(context, profileId, 'hardware', uh.id!, sellPrice, totalOwned <= 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alert,
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.alert.withValues(alpha: 0.3)),
                      backgroundColor: AppColors.surfaceError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      'SELL · +$sellPrice',
                      style: AppTextStyles.button(color: AppColors.alert).copyWith(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canUpgrade ? () => _handleUpgrade(profileId, 'hardware', uh.id!) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(
                        color: canUpgrade ? AppColors.primary : AppColors.border,
                      ),
                      backgroundColor: canUpgrade ? AppColors.surfaceSuccess : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: AppTextStyles.button(
                        color: canUpgrade ? AppColors.primary : AppColors.textMuted,
                      ).copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _UpgradeStatRow extends StatelessWidget {
  const _UpgradeStatRow({
    required this.label,
    required this.current,
    this.next,
    this.delta,
  });

  final String label;
  final String current;
  final String? next;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(color: AppColors.textMuted).copyWith(fontSize: 12),
            ),
          ),
          if (next == null)
            Text(
              current,
              style: AppTextStyles.dataMono(color: AppColors.textHigh),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current,
                  style: AppTextStyles.body(color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: AppColors.iconLow, size: 12),
                const SizedBox(width: 8),
                Text(
                  next!,
                  style: AppTextStyles.dataMono(color: AppColors.primary),
                ),
                if (delta != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '($delta)',
                    style: AppTextStyles.caption(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]
              ],
            ),
        ],
      ),
    );
  }
}
