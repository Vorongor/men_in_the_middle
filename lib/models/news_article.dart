/// A single News Portal entry (Screen 10.1/10.2) — either static lore
/// (loaded from assets/data/news_lore.json) or generated from the player's
/// own attack_log by [NewsGenerator].
class NewsArticle {
  final String title;
  final String category;
  final String time;
  final String body;

  const NewsArticle({
    required this.title,
    required this.category,
    required this.time,
    required this.body,
  });
}
