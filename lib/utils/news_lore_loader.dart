import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/news_article.dart';

/// Loads the static lore articles for the News Portal (Screen 10.1) —
/// flavor content, not tied to the player's own history. Mirrors
/// `legend_loader.dart`'s pattern: a plain asset read, no DB/seeding
/// involved since this is display-only content, not something the game
/// logic queries.
Future<List<NewsArticle>> loadNewsLore() async {
  final raw = await rootBundle.loadString('assets/data/news_lore.json');
  final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  return list
      .map((m) => NewsArticle(
            title: m['title'] as String,
            category: m['category'] as String,
            time: m['time'] as String,
            body: m['body'] as String,
          ))
      .toList();
}
