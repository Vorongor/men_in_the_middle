import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/active_contract.dart';
import '../models/economy_tuning.dart';
import '../models/profile.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../repos/target_repository.dart';
import '../state/player_session.dart';
import '../utils/app_logger.dart';
import '../utils/async_value_ext.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../utils/wanted_effects.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/onboarding_banner.dart';

final activeContractsProvider =
    FutureProvider.autoDispose<List<ContractDetails>>((ref) async {
      final session = ref.watch(playerSessionProvider).valueOrNull;
      if (session == null || session.profile.id == null) return const [];
      final targetRepo = ref.watch(targetRepositoryProvider);
      
      var contracts = await targetRepo.fetchActiveContracts(session.profile.id!);
      if (contracts.isEmpty) {
        final inventoryRepo = ref.watch(inventoryRepositoryProvider);
        final ownedSoft = await inventoryRepo.fetchOwnedSoftware(session.profile.id!);
        final ownedSoftTypeIds = ownedSoft.map((s) => s.catalogItem.softTypeId).toList();
        
        await targetRepo.refreshContracts(
          session.profile,
          payFee: false,
          ownedSoftTypeIds: ownedSoftTypeIds,
        );
        contracts = await targetRepo.fetchActiveContracts(session.profile.id!);
      }
      return contracts;
    });

class TargetBoardScreen extends ConsumerStatefulWidget {
  const TargetBoardScreen({super.key});

  @override
  ConsumerState<TargetBoardScreen> createState() => _TargetBoardScreenState();
}

class _TargetBoardScreenState extends ConsumerState<TargetBoardScreen> {
  static final _log = AppLogger.of('TargetBoardScreen');

  bool _isRefreshing = false;
  bool _startingCleanup = false;

  Future<void> _startCleanup(int profileId) async {
    setState(() => _startingCleanup = true);
    try {
      final contractId = await ref
          .read(targetRepositoryProvider)
          .ensureCleanUpContract(profileId);
      if (mounted) {
        await Navigator.pushNamed(
          context,
          Routes.attackPrep,
          arguments: AttackPrepArgs(contractId: contractId),
        );
      }
    } catch (e) {
      _log.warning('ensureCleanUpContract($profileId) failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF240C0C),
            content: Text(
              'CLEANUP DISPATCH FAILED: $e',
              style: GoogleFonts.shareTechMono(color: Colors.redAccent),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingCleanup = false);
    }
  }

  Future<void> _handleRefresh(int currentBalance, EconomyTuning tuning, bool isFree) async {
    final fee = isFree ? 0 : tuning.boardRefreshFee;
    if (currentBalance < fee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF240C0C),
          content: Text(
            'INSUFFICIENT EPTS BALANCE TO REFRESH SCANNER',
            style: GoogleFonts.shareTechMono(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      final session = ref.read(playerSessionProvider).valueOrNull;
      if (session != null) {
        final inventoryRepo = ref.read(inventoryRepositoryProvider);
        final ownedSoft = await inventoryRepo.fetchOwnedSoftware(session.profile.id!);
        final ownedSoftTypeIds = ownedSoft.map((s) => s.catalogItem.softTypeId).toList();

        await ref
            .read(targetRepositoryProvider)
            .refreshContracts(session.profile, payFee: !isFree, ownedSoftTypeIds: ownedSoftTypeIds);
        await ref.read(playerSessionProvider.notifier).refresh();
        ref.invalidate(activeContractsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0C160C),
              content: Text(
                isFree
                    ? 'EMERGENCY SCAN COMPLETE (FREE)'
                    : 'TARGET SCAN COMPLETELY REFRESHED ($fee EPTS DEDUCTED)',
                style: GoogleFonts.shareTechMono(color: Colors.greenAccent),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _log.warning('refreshContracts failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF240C0C),
            content: Text(
              'REFRESH FAILED: $e',
              style: GoogleFonts.shareTechMono(color: Colors.redAccent),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _calculateDifficulty(int defense, int softwarePower) {
    if (defense <= softwarePower * 0.8) {
      return 'LOW';
    } else if (defense > softwarePower * 1.2) {
      return 'HIGH';
    }
    return 'MEDIUM';
  }

  Color _getDiffColor(String diff) {
    switch (diff) {
      case 'LOW':
        return Colors.greenAccent;
      case 'MEDIUM':
        return Colors.orangeAccent;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playerSessionProvider);
    final profile = sessionState.valueOrNull?.profile;

    if (profile == null) {
      return const GameScaffold(
        screenNum: '5.1',
        screenName: 'TARGET BOARD',
        body: Center(
          child: Text(
            'Not authenticated',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    if (WantedEffects.isRaided(profile.wanted)) {
      return GameScaffold(
        screenNum: '5.1',
        screenName: 'TARGET BOARD',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'TOO HOT. LAY LOW.',
                  style: GoogleFonts.cinzel(
                    color: Colors.redAccent,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Wanted is maxed out — every eye in the sector is on you. '
                  'The board is locked until you scrub your traces.',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _startingCleanup
                        ? null
                        : () => _startCleanup(profile.id!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      disabledForegroundColor: Colors.white24,
                      side: const BorderSide(color: Color(0xFF1E351E)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _startingCleanup
                          ? 'DISPATCHING...'
                          : 'INITIATE CLEAN UP TRACES',
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeContractsAsync = ref.watch(activeContractsProvider);
    final softwarePower = profile.softwarePower;
    final tuningAsync = ref.watch(economyTuningProvider);
    final tuning = tuningAsync.valueOrNull ?? const EconomyTuning(
      boardRefreshFee: 10,
      sellRatio: 0.5,
      contractTtlHours: 24,
      insuranceMinReward: 10,
    );

    return GameScaffold(
      screenNum: '5.1',
      screenName: 'TARGET BOARD',
      body: Stack(
        children: [
          _boardColumn(activeContractsAsync, softwarePower, profile, tuning),
          const OnboardingTip(
            tipKey: 'target_board',
            message:
                'Tap a contract to see its defense and the recommended '
                'tool before you commit to an attack.',
          ),
        ],
      ),
    );
  }

  Widget _boardColumn(
    AsyncValue<List<ContractDetails>> activeContractsAsync,
    int softwarePower,
    Profile profile,
    EconomyTuning tuning,
  ) {
    return Column(
      children: [
        Expanded(
          child: activeContractsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
            error: (err, _) => Center(
              child: Text(
                'Error loading targets: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (contracts) {
              if (contracts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.white12,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NO WIRELESS NETWORKS DETECTED',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white38,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan database is empty. Force a network scan below to request fresh targets.',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: contracts.length,
                itemBuilder: (context, i) {
                  final c = contracts[i];
                  final diff = _calculateDifficulty(c.defense, softwarePower);

                  return InkWell(
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.targetDetail,
                        arguments: TargetDetailArgs(contractId: c.id),
                      );
                      // Refresh board list in case it was completed
                      ref.invalidate(activeContractsProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF111111)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C160C),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF1E351E),
                              ),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.shareTechMono(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.targetName,
                                  style: GoogleFonts.shareTechMono(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${c.missionName.toUpperCase()}  ·  BOUNTY: ${c.eptsReward} EPTS',
                                  style: GoogleFonts.shareTechMono(
                                    color: Colors.white30,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getDiffColor(
                                diff,
                              ).withValues(alpha: 0.08),
                              border: Border.all(
                                color: _getDiffColor(
                                  diff,
                                ).withValues(alpha: 0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              diff,
                              style: GoogleFonts.shareTechMono(
                                color: _getDiffColor(diff),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white10,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF111111))),
            color: Color(0xFF070707),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isRefreshing
                  ? null
                  : () {
                      final contracts = activeContractsAsync.valueOrNull ?? const [];
                      final isFree = contracts.isEmpty;
                      _handleRefresh(profile.eptsBalance, tuning, isFree);
                    },
              style: OutlinedButton.styleFrom(
                backgroundColor: (activeContractsAsync.valueOrNull ?? const []).isEmpty || profile.eptsBalance >= tuning.boardRefreshFee
                    ? const Color(0xFF0C160C)
                    : Colors.transparent,
                foregroundColor: Colors.greenAccent,
                disabledForegroundColor: Colors.white24,
                side: BorderSide(
                  color: (activeContractsAsync.valueOrNull ?? const []).isEmpty || profile.eptsBalance >= tuning.boardRefreshFee
                      ? Colors.greenAccent
                      : const Color(0xFF222222),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                _isRefreshing
                    ? 'RECALIBRATING RF RECEIVER...'
                    : (activeContractsAsync.valueOrNull ?? const []).isEmpty
                        ? 'EMERGENCY SCAN  ·  FREE'
                        : 'REFRESH WIRELESS SCAN  ·  ${tuning.boardRefreshFee} EPTS',
                style: GoogleFonts.shareTechMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
