import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/account_with_profile.dart';
import '../state/player_session.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/onboarding_banner.dart';
import 'target_board_screen.dart';

class HomePageScreen extends ConsumerWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);

    return session.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Session error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (awp) {
        // Route guard: session expired → back to login
        if (awp == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          });
          return const Scaffold(backgroundColor: Colors.black);
        }
        return _HomePageBody(data: awp);
      },
    );
  }
}

class _HomePageBody extends StatelessWidget {
  const _HomePageBody({required this.data});
  final AccountWithProfile data;

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      screenNum: '3',
      screenName: 'HOME PAGE',
      showHomeButton: false,
      body: Stack(
        children: [
          Column(
            children: [
              // TOP ~15% — User info card
              _UserInfoCard(data: data),
              // MIDDLE ~50% — Target board preview
              Expanded(flex: 50, child: _TargetBoardPreview(data: data)),
              // BOTTOM ~35% — Navigation icon grid
              _NavIconGrid(),
            ],
          ),
          const OnboardingTip(
            tipKey: 'home',
            message:
                'This is your hub. Check the Target Board for contracts, '
                'then gear up in the Store and Market before you attack.',
          ),
        ],
      ),
    );
  }
}

// ── User Info Card ────────────────────────────────────────────────────────────

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.data});
  final AccountWithProfile data;

  @override
  Widget build(BuildContext context) {
    final a = data.account;
    final p = data.profile;
    final l = data.level;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, Routes.profile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(bottom: BorderSide(color: Color(0xFF222222))),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: Colors.white38, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.pseudo,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${l.name}  ·  Lv.${l.id}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'XP ${p.experience}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  'Rating ${p.rating}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Target Board Preview ──────────────────────────────────────────────────────

class _TargetBoardPreview extends ConsumerWidget {
  const _TargetBoardPreview({required this.data});
  final AccountWithProfile data;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final activeContractsAsync = ref.watch(activeContractsProvider);
    final softwarePower = data.profile.softwarePower;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                'TARGET BOARD PREVIEW',
                style: GoogleFonts.cinzel(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.targetBoard),
                child: const Text(
                  'View All →',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF111111), height: 1),
        Expanded(
          child: activeContractsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
            error: (err, _) => Center(
              child: Text(
                'Scanner error',
                style: GoogleFonts.shareTechMono(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ),
            data: (contracts) {
              if (contracts.isEmpty) {
                return Center(
                  child: Text(
                    'NO TARGETS DETECTED IN SCAN RANGE',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              final previewList = contracts.take(3).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: previewList.length,
                itemBuilder: (context, i) {
                  final c = previewList[i];
                  final diff = _calculateDifficulty(c.defense, softwarePower);

                  return InkWell(
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.targetDetail,
                        arguments: TargetDetailArgs(contractId: c.id),
                      );
                      ref.invalidate(activeContractsProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF111111)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.targetName,
                                  style: GoogleFonts.shareTechMono(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  c.missionName.toUpperCase(),
                                  style: GoogleFonts.shareTechMono(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
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
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
      ],
    );
  }
}

// ── Nav Icon Grid ─────────────────────────────────────────────────────────────

class _NavIconGrid extends StatelessWidget {
  const _NavIconGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.storefront_outlined, 'Store', Routes.store),
      (Icons.memory_outlined, 'Market', Routes.market),
      (Icons.build_outlined, 'Workshop', Routes.workshop),
      (Icons.article_outlined, 'News', Routes.news),
    ];

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.85,
        children: items
            .map(
              (item) => _NavIcon(
                icon: item.$1,
                label: item.$2,
                onTap: () => Navigator.pushNamed(context, item.$3),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white54, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
