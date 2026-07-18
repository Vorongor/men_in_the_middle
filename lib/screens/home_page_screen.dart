import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account_with_profile.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text(
            'Session error: $e',
            style: AppTextStyles.body(color: AppColors.alert),
          ),
        ),
      ),
      data: (awp) {
        // Route guard: session expired → back to login
        if (awp == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          });
          return const Scaffold(backgroundColor: AppColors.bg);
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
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppColors.textMuted, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.pseudo,
                    style: AppTextStyles.sectionLabel(color: AppColors.text).copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${l.name}  ·  Lv.${l.id}',
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'XP ${p.experience}',
                  style: AppTextStyles.caption(color: AppColors.textHigh),
                ),
                Text(
                  'Rating ${p.rating}',
                  style: AppTextStyles.caption(color: AppColors.textHigh),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: AppColors.iconLow, size: 16),
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
        return AppColors.primary;
      case 'MEDIUM':
        return AppColors.warning;
      default:
        return AppColors.alert;
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
                style: AppTextStyles.sectionLabel(color: AppColors.textMuted).copyWith(
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.targetBoard),
                child: Text(
                  'View All →',
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: activeContractsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Center(
              child: Text(
                'Scanner error',
                style: AppTextStyles.body(color: AppColors.alert),
              ),
            ),
            data: (contracts) {
              if (contracts.isEmpty) {
                return Center(
                  child: Text(
                    'NO TARGETS DETECTED IN SCAN RANGE',
                    style: AppTextStyles.body(color: AppColors.textMuted),
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
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSuccess,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: AppColors.borderSuccess,
                              ),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: AppTextStyles.dataMono(color: AppColors.primary).copyWith(
                                fontSize: 11,
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
                                  style: AppTextStyles.dataMono(color: AppColors.text),
                                ),
                                Text(
                                  c.missionName.toUpperCase(),
                                  style: AppTextStyles.caption(color: AppColors.textMuted),
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
                              color: _getDiffColor(diff).withValues(alpha: 0.08),
                              border: Border.all(
                                color: _getDiffColor(diff).withValues(alpha: 0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              diff,
                              style: AppTextStyles.caption(color: _getDiffColor(diff)).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.iconLow,
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
      color: AppColors.bg,
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textHigh, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

