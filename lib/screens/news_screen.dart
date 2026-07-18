import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_article.dart';
import '../repos/attack_repository.dart';
import '../services/news_state_service.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/async_value_ext.dart';
import '../utils/news_generator.dart';
import '../utils/news_lore_loader.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../widgets/app_snack.dart';
import '../widgets/game_scaffold.dart';

/// Screen 10.1 — a mix of the player's own attack history (dressed up as
/// tabloid headlines by [NewsGenerator]) and static lore articles. No more
/// hardcoded article list: both sources are loaded at build time.
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late Future<List<NewsArticle>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final profile = ref.read(playerSessionProvider).valueOrNull?.profile;
    if (profile?.id == null) {
      _loadFuture = loadNewsLore().then(
        (lore) => lore.where((a) => !NewsStateService.instance.isDismissed(a.id)).toList(),
      );
      return;
    }

    final attackRepo = ref.read(attackRepositoryProvider);
    _loadFuture = Future.wait([
      attackRepo.recentAttacks(profile!.id!, limit: 20),
      loadNewsLore(),
    ]).then((results) {
      final history = results[0] as List<AttackHistoryEntry>;
      final lore = results[1] as List<NewsArticle>;
      final allArticles = [...history.map(NewsGenerator.articleFor), ...lore];
      return allArticles.where((a) => !NewsStateService.instance.isDismissed(a.id)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      screenNum: '10.1',
      screenName: 'NEWS PORTAL',
      body: FutureBuilder<List<NewsArticle>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          final articles = snapshot.data ?? const <NewsArticle>[];
          if (articles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'NO NEWS ARTICLES AVAILABLE\nNew entries appear after target attacks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 13, height: 1.5),
                ),
              ),
            );
          }

          final hasRead = articles.any((a) => NewsStateService.instance.isRead(a.id));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, i) {
                    final article = articles[i];
                    return Dismissible(
                      key: Key(article.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        color: AppColors.surfaceError,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: AppSpacing.xl),
                        child: const Icon(Icons.delete_outline, color: AppColors.alert),
                      ),
                      secondaryBackground: Container(
                        color: AppColors.surfaceError,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        child: const Icon(Icons.delete_outline, color: AppColors.alert),
                      ),
                      onDismissed: (direction) async {
                        await NewsStateService.instance.dismiss(article.id);
                        if (context.mounted) {
                          showAppSnack(
                            context,
                            'ARTICLE DISMISSED',
                            kind: AppSnackKind.info,
                            action: SnackBarAction(
                              label: 'UNDO',
                              textColor: Colors.amberAccent,
                              onPressed: () async {
                                await NewsStateService.instance.undismiss(article.id);
                                if (context.mounted) {
                                  setState(_load);
                                }
                              },
                            ),
                          );
                          setState(_load);
                        }
                      },
                      child: _NewsRow(
                        article: article,
                        isRead: NewsStateService.instance.isRead(article.id),
                        onTap: () async {
                          await NewsStateService.instance.markAsRead(article.id);
                          if (context.mounted) {
                            await Navigator.pushNamed(
                              context,
                              Routes.newsItem,
                              arguments: NewsItemArgs(article: article),
                            );
                            if (context.mounted) {
                              setState(_load);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              if (hasRead)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onPressed: () async {
                      final readIds = articles
                          .where((a) => NewsStateService.instance.isRead(a.id))
                          .map((a) => a.id)
                          .toList();
                      if (readIds.isEmpty) return;

                      await NewsStateService.instance.dismissMultiple(readIds);
                      if (context.mounted) {
                        showAppSnack(
                          context,
                          'CLEARED ${readIds.length} READ ARTICLES',
                          kind: AppSnackKind.info,
                          action: SnackBarAction(
                            label: 'UNDO',
                            textColor: Colors.amberAccent,
                            onPressed: () async {
                              await NewsStateService.instance.undismissMultiple(readIds);
                              if (context.mounted) {
                                setState(_load);
                              }
                            },
                          ),
                        );
                        setState(_load);
                      }
                    },
                    child: const Text(
                      'CLEAR READ',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({
    required this.article,
    required this.isRead,
    required this.onTap,
  });

  final NewsArticle article;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = isRead ? 0.4 : 1.0;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.article_outlined,
                    color: Colors.amberAccent, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(article.category,
                            style: const TextStyle(
                                color: Colors.amberAccent, fontSize: 10)),
                        const Text('  ·  ',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 10)),
                        Text(article.time,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
