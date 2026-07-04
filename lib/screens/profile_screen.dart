import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../repos/attack_repository.dart';
import '../services/level_service.dart';
import '../state/player_session.dart';
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
    if (wanted >= 75) return Colors.redAccent;
    if (wanted >= 50) return Colors.orangeAccent;
    if (wanted >= 25) return Colors.amberAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);

    return session.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Text('$e', style: const TextStyle(color: Colors.red))),
      ),
      data: (awp) {
        if (awp == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          });
          return const Scaffold(backgroundColor: Colors.black);
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section('AGENT PROFILE'),
                      _Row('ID', '#${a.id}'),
                      _Row('Handle', a.pseudo),
                      _Row('Rank', '${l.name}  ·  Lv.${l.id}'),
                      const SizedBox(height: 6),
                      _ExpBar(experience: p.experience, progress: progress),
                      const SizedBox(height: 8),
                      _Section('CAPABILITIES'),
                      _Row('Software Power', '${p.softwarePower}'),
                      _Row('Hardware Power', '${p.hardwarePower}'),
                      _Row('EPTS Balance', '${p.eptsBalance}'),
                      const SizedBox(height: 8),
                      _Section('REPUTATION'),
                      _Row('Rating', '${p.rating}'),
                      _WantedRow(wanted: p.wanted, color: _wantedColor(p.wanted)),
                      _Row('Black Trust', '${p.blackTrust} / 100'),
                      _Row('Popularity', '${p.popularity}'),
                      const SizedBox(height: 8),
                      _Section('RECENT OPERATIONS'),
                      if (recent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'No operations logged yet.',
                            style: TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        )
                      else
                        ...recent.map((e) => _HistoryRow(entry: e)),
                      const SizedBox(height: 8),
                      _Section('LEGEND'),
                      const SizedBox(height: 8),
                      Text(
                        p.legend,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.description,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
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
        foregroundColor: Colors.amber,
        side: BorderSide(color: Colors.amber.withAlpha(100)),
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
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.cinzel(
                  fontSize: 11, color: Colors.white54, letterSpacing: 3)),
          const Divider(color: Colors.white12, height: 8),
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
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
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
          const SizedBox(
            width: 130,
            child: Text('Wanted',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: wanted / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$wanted / 100',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
            const Text('Experience',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const Spacer(),
            Text(
              isMax ? '$experience XP · MAX RANK' : '$experience XP',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: const Color(0xFF1A1A1A),
            valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
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
        'success' => Colors.greenAccent,
        'hard' => Colors.orangeAccent,
        _ => Colors.redAccent,
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$sign${entry.eptsDelta} EPTS',
            style: TextStyle(color: _resultColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
