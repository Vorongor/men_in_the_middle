import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hardware_item.dart';
import '../models/user_hardware.dart';
import '../repos/inventory_repository.dart';
import '../services/audio_service.dart';
import '../state/player_session.dart';
import '../utils/app_logger.dart';
import '../utils/async_value_ext.dart';
import '../utils/constants.dart';
import '../utils/route_args.dart';
import '../utils/wanted_effects.dart';
import '../widgets/app_snack.dart';
import '../widgets/game_scaffold.dart';

class MarketItemScreen extends ConsumerStatefulWidget {
  const MarketItemScreen({super.key});

  @override
  ConsumerState<MarketItemScreen> createState() => _MarketItemScreenState();
}

class _MarketItemScreenState extends ConsumerState<MarketItemScreen> {
  static final _log = AppLogger.of('MarketItemScreen');

  bool _isPurchasing = false;

  Future<void> _handleBuy(int profileId, HardwareItem item) async {
    setState(() => _isPurchasing = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.buyHardware(profileId, item);

      // Refresh session profile state
      await ref.read(playerSessionProvider.notifier).refresh();
      unawaited(AudioService.instance.playSfx(AppAudio.sfxPurchase));

      if (mounted) {
        showAppSnack(
          context,
          'SUCCESSFULLY INSTALLED: ${item.name.toUpperCase()}',
          kind: AppSnackKind.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _log.warning('Purchase of ${item.name} failed', e);
      if (mounted) {
        showAppSnack(
          context,
          'INSTALLATION FAILED: $e',
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
    final args = ModalRoute.of(context)!.settings.arguments as MarketItemArgs?;
    if (args == null) {
      return const GameScaffold(
        screenNum: '8.2',
        screenName: 'MARKET ITEM',
        body: Center(child: Text('Invalid arguments')),
      );
    }

    final item = args.item;
    final session = ref.watch(playerSessionProvider).valueOrNull;
    final profile = session?.profile;

    if (profile == null) {
      return const GameScaffold(
        screenNum: '8.2',
        screenName: 'MARKET ITEM',
        body: Center(child: Text('Not authenticated')),
      );
    }

    return FutureBuilder<List<OwnedHardware>>(
      future: ref.read(inventoryRepositoryProvider).fetchOwnedHardware(profile.id!),
      builder: (context, snapshot) {
        final owned = snapshot.data ?? <OwnedHardware>[];
        final isOwned = owned.any((o) => o.catalogItem.id == item.id);

        final levelLocked = profile.levelId < item.reqLevel;
        final trustLocked = profile.blackTrust < item.reqBlackTrust;
        final isLocked = levelLocked || trustLocked;

        final effectivePrice = WantedEffects.effectivePrice(item.basePrice, profile.wanted);
        final isAffordable = profile.eptsBalance >= effectivePrice;

        // Button state
        final canBuy = !isOwned && !isLocked && isAffordable && !_isPurchasing;
        String buttonText = WantedEffects.isRiskTaxed(profile.wanted)
            ? 'BUY  ·  $effectivePrice EPTS (RISK TAX)'
            : 'BUY  ·  $effectivePrice EPTS';

        if (isOwned) {
          buttonText = 'ALREADY INSTALLED';
        } else if (levelLocked) {
          buttonText = 'LOCKED (LEVEL ${item.reqLevel} REQ)';
        } else if (trustLocked) {
          buttonText = 'LOCKED (TRUST ${item.reqBlackTrust} REQ)';
        } else if (!isAffordable) {
          buttonText = 'INSUFFICIENT EPTS BALANCE';
        } else if (_isPurchasing) {
          buttonText = 'INSTALLING HARDWARE...';
        }

        return GameScaffold(
          screenNum: '8.2',
          screenName: 'MARKET ITEM',
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                        color: isLocked ? const Color(0xFF160A0A) : const Color(0xFF0C160C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLocked ? const Color(0xFF2D1414) : const Color(0xFF1E351E),
                        ),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline : Icons.dns,
                        color: isLocked ? Colors.redAccent : Colors.greenAccent,
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
                            style: GoogleFonts.shareTechMono(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'HARDWARE CLASS: ${item.hwType}',
                            style: GoogleFonts.shareTechMono(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$effectivePrice epts',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF111111), height: 32),
                Text(
                  item.description,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Specifications Section
                Text(
                  'SYSTEM PARAMETERS',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _StatRow('Compute Power Contribution', '+${item.initComputePower} FLOPS'),
                _StatRow('Power Consumption', '${item.initPowerDraw} W'),
                _StatRow('Exp Sockets Available', '${item.sockets}'),

                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: canBuy ? () => _handleBuy(profile.id!, item) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      disabledForegroundColor: Colors.white24,
                      side: BorderSide(
                        color: canBuy ? Colors.greenAccent : const Color(0xFF222222),
                      ),
                      backgroundColor: canBuy ? const Color(0xFF0C160C) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
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
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
