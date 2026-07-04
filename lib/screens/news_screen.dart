import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_article.dart';
import '../repos/attack_repository.dart';
import '../state/player_session.dart';
import '../utils/async_value_ext.dart';
import '../utils/news_generator.dart';
import '../utils/news_lore_loader.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
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
      _loadFuture = loadNewsLore();
      return;
    }

    final attackRepo = ref.read(attackRepositoryProvider);
    _loadFuture = Future.wait([
      attackRepo.recentAttacks(profile!.id!, limit: 20),
      loadNewsLore(),
    ]).then((results) {
      final history = results[0] as List<AttackHistoryEntry>;
      final lore = results[1] as List<NewsArticle>;
      return [...history.map(NewsGenerator.articleFor), ...lore];
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
              child: Text('NO SIGNAL', style: TextStyle(color: Colors.white24)),
            );
          }

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, i) {
              final article = articles[i];
              return _NewsRow(
                article: article,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.newsItem,
                  arguments: NewsItemArgs(article: article),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A0D),
                borderRadius: BorderRadius.circular(4),
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
    );
  }
}
