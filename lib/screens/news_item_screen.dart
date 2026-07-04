import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/route_args.dart';
import '../widgets/game_scaffold.dart';

class NewsItemScreen extends StatelessWidget {
  const NewsItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as NewsItemArgs?;

    if (args == null) {
      return const GameScaffold(
        screenNum: '10.2',
        screenName: 'NEWS ARTICLE',
        body: Center(
          child: Text('Invalid arguments', style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    final article = args.article;

    return GameScaffold(
      screenNum: '10.2',
      screenName: 'NEWS ARTICLE',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A0D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(article.category,
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10,
                          letterSpacing: 1)),
                ),
                const SizedBox(width: 8),
                Text(article.time,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Text(article.title,
                style: GoogleFonts.cinzel(
                    color: Colors.white, fontSize: 16, letterSpacing: 1)),
            const Divider(color: Color(0xFF1A1A1A), height: 24),
            Text(article.body,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.7)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
