import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/software_item.dart';
import '../models/user_software.dart';
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
import '../utils/wanted_effects.dart';
import '../widgets/app_snack.dart';
import '../widgets/game_scaffold.dart';

class StoreItemScreen extends ConsumerStatefulWidget {
  const StoreItemScreen({super.key});

  @override
  ConsumerState<StoreItemScreen> createState() => _StoreItemScreenState();
}

class _StoreItemScreenState extends ConsumerState<StoreItemScreen> {
  static final _log = AppLogger.of('StoreItemScreen');

  bool _isPurchasing = false;

  String _getSoftTypeName(int typeId) {
    switch (typeId) {
      case 1:
        return 'Phishing';
      case 2:
        return 'Bruteforce';
      case 3:
        return 'DDoS';
      case 4:
        return 'Exploit';
      default:
        return 'Utility';
    }
  }

  Future<void> _handleBuy(int profileId, SoftwareItem item) async {
    setState(() => _isPurchasing = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.buySoftware(profileId, item);

      // Refresh Riverpod profile session state
      await ref.read(playerSessionProvider.notifier).refresh();
      unawaited(AudioService.instance.playSfx(AppAudio.sfxPurchase));

      if (mounted) {
        showAppSnack(
          context,
          'SUCCESSFULLY PURCHASED: ${item.name.toUpperCase()}',
          kind: AppSnackKind.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _log.warning('Purchase of ${item.name} failed', e);
      if (mounted) {
        showAppSnack(
          context,
          'PURCHASE FAILED: $e',
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as StoreItemArgs?;
    if (args == null) {
      return const GameScaffold(
        screenNum: '6.2',
        screenName: 'STORE ITEM',
        body: Center(child: Text('Invalid arguments')),
      );
    }
    
    final item = args.item;
    final session = ref.watch(playerSessionProvider).valueOrNull;
    final profile = session?.profile;

    if (profile == null) {
      return const GameScaffold(
        screenNum: '6.2',
        screenName: 'STORE ITEM',
        body: Center(child: Text('Not authenticated')),
      );
    }

    // Check ownership
    return FutureBuilder<List<OwnedSoftware>>(
      future: ref.read(inventoryRepositoryProvider).fetchOwnedSoftware(profile.id!),
      builder: (context, snapshot) {
        final owned = snapshot.data ?? <OwnedSoftware>[];
        final isOwned = owned.any((o) => o.catalogItem.id == item.id);
        
        final levelLocked = profile.levelId < item.reqLevel;
        final trustLocked = profile.blackTrust < item.reqBlackTrust;
        final isLocked = levelLocked || trustLocked;

        final effectivePrice = WantedEffects.effectivePrice(item.basePrice, profile.wanted);
        final isAffordable = profile.eptsBalance >= effectivePrice;

        // Button state calculation
        final canBuy = !isOwned && !isLocked && isAffordable && !_isPurchasing;
        String buttonText = WantedEffects.isRiskTaxed(profile.wanted)
            ? 'BUY  ·  $effectivePrice EPTS (RISK TAX)'
            : 'BUY  ·  $effectivePrice EPTS';

        if (isOwned) {
          buttonText = 'ALREADY OWNED';
        } else if (levelLocked) {
          buttonText = 'LOCKED (LEVEL ${item.reqLevel} REQ)';
        } else if (trustLocked) {
          buttonText = 'LOCKED (TRUST ${item.reqBlackTrust} REQ)';
        } else if (!isAffordable) {
          buttonText = 'INSUFFICIENT EPTS BALANCE';
        } else if (_isPurchasing) {
          buttonText = 'EXECUTING TRANSACTION...';
        }

        return GameScaffold(
          screenNum: '6.2',
          screenName: 'STORE ITEM',
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
                        color: isLocked ? AppColors.surfaceError : AppColors.surfaceSuccess,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: isLocked ? AppColors.alert.withValues(alpha: 0.3) : AppColors.borderSuccess,
                        ),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline : Icons.terminal,
                        color: isLocked ? AppColors.alert : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.dataMono(color: AppColors.text).copyWith(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getSoftTypeName(item.softTypeId).toUpperCase(),
                            style: AppTextStyles.caption(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$effectivePrice epts',
                      style: AppTextStyles.dataMono(color: AppColors.primary).copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  item.description,
                  style: AppTextStyles.body(color: AppColors.textHigh).copyWith(
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                
                // Specifications Section
                Text(
                  'UTILITY PARAMETERS',
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _StatRow('Base Attack Power', '${item.baseAttack}'),
                _StatRow('Penetration Rating', '${item.basePenetration}'),
                _StatRow('Trace Footprint', '${item.baseTrace}'),
                _StatRow('Mod Sockets Available', '${item.sockets}'),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: canBuy ? () => _handleBuy(profile.id!, item) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(
                        color: canBuy ? AppColors.primary : AppColors.border,
                      ),
                      backgroundColor: canBuy ? AppColors.surfaceSuccess : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: AppTextStyles.button(
                        color: canBuy ? AppColors.primary : AppColors.textMuted,
                      ).copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;

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
          Text(
            value,
            style: AppTextStyles.dataMono(color: AppColors.textHigh),
          ),
        ],
      ),
    );
  }
}
