import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/active_contract.dart';
import '../models/user_software.dart';
import '../repos/inventory_repository.dart';
import '../repos/target_repository.dart';
import '../state/player_session.dart';
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
      return const GameScaffold(
        screenNum: '5.2',
        screenName: 'TARGET DETAIL',
        body: Center(child: Text('Invalid route arguments')),
      );
    }

    final profile = ref.watch(playerSessionProvider).valueOrNull?.profile;
    if (profile == null) {
      return const GameScaffold(
        screenNum: '5.2',
        screenName: 'TARGET DETAIL',
        body: Center(child: Text('Not authenticated')),
      );
    }

    return FutureBuilder<(ContractDetails?, List<OwnedSoftware>)>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GameScaffold(
            screenNum: '5.2',
            screenName: 'TARGET DETAIL',
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.$1 == null) {
          return GameScaffold(
            screenNum: '5.2',
            screenName: 'TARGET DETAIL',
            body: Center(
              child: Text(
                'Failed to load target details',
                style: GoogleFonts.shareTechMono(color: Colors.redAccent),
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
                        color: const Color(0xFF0C160C),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1E351E)),
                      ),
                      child: const Icon(Icons.radar, color: Colors.greenAccent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.targetName,
                            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'NODE ID: #${c.id.toString().padLeft(4, '0')}  ·  ${c.targetTypeName.toUpperCase()}',
                            style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 11, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF111111), height: 32),
                
                Text(
                  'MISSION CLASSIFICATION',
                  style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  c.missionName.toUpperCase(),
                  style: GoogleFonts.shareTechMono(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  c.missionDescription,
                  style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),

                Text(
                  'TARGET PROFILE SPECTRAL PARAMETERS',
                  style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
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
                  style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070707),
                    border: Border.all(color: const Color(0xFF111111)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasRecommendedSoft ? Icons.check_circle : Icons.warning_amber,
                        color: hasRecommendedSoft ? Colors.greenAccent : Colors.amberAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${softwareTypeName(c.missionPrimarySoftTypeId).toUpperCase()} UTILITY',
                              style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Effectiveness: +100% Damage (x2 Mult) against node structure.',
                              style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        hasRecommendedSoft ? 'READY' : 'STORE LACK',
                        style: GoogleFonts.shareTechMono(
                          color: hasRecommendedSoft ? Colors.greenAccent : Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
                      foregroundColor: Colors.greenAccent,
                      disabledForegroundColor: Colors.white24,
                      side: BorderSide(
                        color: levelLocked ? const Color(0xFF222222) : Colors.greenAccent,
                      ),
                      backgroundColor: levelLocked ? Colors.transparent : const Color(0xFF0C160C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.shareTechMono(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
    Color valColor = Colors.white70;
    if (highlight) {
      valColor = Colors.greenAccent;
    } else if (warning) {
      valColor = Colors.redAccent;
    }

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
              color: valColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
