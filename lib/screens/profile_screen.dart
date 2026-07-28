import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repos/attack_repository.dart';
import '../services/level_service.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/routes.dart';
import '../widgets/game_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<(double, List<AttackHistoryEntry>)> _loadFuture;
  int? _loadedForLevelId;
  int? _loadedForExperience;

  void _load(int levelId, int experience, int? profileId) {
    _loadedForLevelId = levelId;
    _loadedForExperience = experience;
    final attackRepo = ref.read(attackRepositoryProvider);
    _loadFuture = Future.wait([
      LevelService.progressToNextLevel(levelId, experience),
      profileId == null
          ? Future.value(<AttackHistoryEntry>[])
          : attackRepo.recentAttacks(profileId, limit: 5),
    ]).then((res) => (res[0] as double, res[1] as List<AttackHistoryEntry>));
  }

  Color _wantedColor(int wanted) {
    if (wanted >= 75) return AppColors.alert;
    if (wanted >= 50) return AppColors.warning;
    if (wanted >= 25) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);

    return session.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
            child: Text('$e', style: const TextStyle(color: AppColors.alert))),
      ),
      data: (awp) {
        if (awp == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          });
          return const Scaffold(backgroundColor: AppColors.bg);
        }

        final a = awp.account;
        final p = awp.profile;
        final l = awp.level;

        if (_loadedForLevelId != p.levelId || _loadedForExperience != p.experience) {
          _load(p.levelId, p.experience, p.id);
        }

        return GameScaffold(
          screenNum: '4',
          screenName: 'PROFILE',
          body: SafeArea(
            child: FutureBuilder<(double, List<AttackHistoryEntry>)>(
              future: _loadFuture,
              builder: (context, snapshot) {
                final progress = snapshot.data?.$1;
                final recent = snapshot.data?.$2 ?? const <AttackHistoryEntry>[];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section('AGENT PROFILE'),
                      _Row('ID', '#${a.id}'),
                      _Row('Handle', a.pseudo),
                      _Row('Rank', '${l.name}  ·  Lv.${l.id}'),
                      const SizedBox(height: AppSpacing.sm),
                      _ExpBar(experience: p.experience, progress: progress),
                      const SizedBox(height: AppSpacing.sm),
                      _Section('CAPABILITIES'),
                      _Row('Software Power', '${p.softwarePower}'),
                      _Row('Hardware Power', '${p.hardwarePower}'),
                      _Row('EPTS Balance', '${p.eptsBalance}'),
                      const SizedBox(height: AppSpacing.sm),
                      _Section('REPUTATION'),
                      _Row('Rating', '${p.rating}'),
                      _WantedRow(wanted: p.wanted, color: _wantedColor(p.wanted)),
                      _Row('Black Trust', '${p.blackTrust} / 100'),
                      _Row('Popularity', '${p.popularity}'),
                      const SizedBox(height: AppSpacing.sm),
                      _Section('RECENT OPERATIONS'),
                      if (recent.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text(
                            'No operations logged yet.',
                            style: AppTextStyles.body(color: AppColors.textMuted),
                          ),
                        )
                      else
                        ...recent.map((e) => _HistoryRow(entry: e)),
                      const SizedBox(height: AppSpacing.sm),
                      _Section('LEGEND'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        p.legend,
                        style: AppTextStyles.body(color: AppColors.textHigh).copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l.description,
                        style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // DEBUG: simulate earning XP to verify live state update
                      _DebugMutationButton(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Debug button (removed in Step 10 polish) ──────────────────────────────────

class _DebugMutationButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.science_outlined, size: 16),
      label: const Text('DEBUG: +100 XP'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.warning,
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      onPressed: () async {
        await ref
            .read(playerSessionProvider.notifier)
            .updateProfileFields({'experience': 100});
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionLabel(color: AppColors.textMuted).copyWith(
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.dataMono(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _WantedRow extends StatelessWidget {
  const _WantedRow({required this.wanted, required this.color});
  final int wanted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              'Wanted',
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: wanted / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$wanted / 100',
            style: AppTextStyles.dataMono(color: color),
          ),
        ],
      ),
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.experience, required this.progress});
  final int experience;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final value = progress ?? 0.0;
    final isMax = progress == 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Experience',
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
            const Spacer(),
            Text(
              isMax ? '$experience XP · MAX RANK' : '$experience XP',
              style: AppTextStyles.caption(color: AppColors.textHigh),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final AttackHistoryEntry entry;

  Color get _resultColor => switch (entry.result) {
        'success' => AppColors.primary,
        'hard' => AppColors.warning,
        _ => AppColors.alert,
      };

  @override
  Widget build(BuildContext context) {
    final sign = entry.eptsDelta > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: _resultColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${entry.targetName} · ${entry.missionName}',
              style: AppTextStyles.body(color: AppColors.textHigh),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$sign${entry.eptsDelta} EPTS',
            style: AppTextStyles.dataMono(color: _resultColor),
          ),
        ],
      ),
    );
  }
}
