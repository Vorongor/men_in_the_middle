import '../models/news_article.dart';
import '../repos/attack_repository.dart';

/// Turns the player's own attack_log into tabloid-style News Portal
/// headlines. Deliberately template-in-code rather than JSON: unlike the
/// game-content catalogs, this is pure flavor text with no gameplay effect,
/// so a small `switch` keeps it simple without a seeding/validation pass.
class NewsGenerator {
  const NewsGenerator._();

  static NewsArticle articleFor(AttackHistoryEntry entry) => NewsArticle(
        title: _headline(entry),
        category: entry.missionName.toUpperCase(),
        time: _formatTime(entry.createdAt),
        body: _body(entry),
      );

  static String _headline(AttackHistoryEntry entry) => switch (entry.result) {
        'success' => '${entry.targetName} Confirms Clean Data Breach',
        'hard' => '${entry.targetName} Reports Intrusion, Traces Found',
        _ => '${entry.targetName} Repels Attempted Intrusion',
      };

  static String _body(AttackHistoryEntry entry) {
    final mission = entry.missionName;
    return switch (entry.result) {
      'success' =>
        '$mission operation against ${entry.targetName} went undetected. '
            'No investigation has been opened; analysts note the attackers '
            'left no discernible trace.',
      'hard' =>
        '${entry.targetName} confirms a breach following a $mission attempt. '
            'Investigators say the intrusion took longer than expected, '
            'leaving behind enough residue to trace some activity.',
      _ =>
        '${entry.targetName} successfully repelled an attempted $mission '
            'intrusion. Security teams credit updated defenses; no data '
            'appears to have been lost.',
    };
  }

  /// `attack_log.created_at` is a SQLite `datetime('now')` string
  /// (`YYYY-MM-DD HH:MM:SS`); trimming to the minute is enough for a news
  /// timestamp without pulling in a date-formatting dependency.
  static String _formatTime(String createdAt) =>
      createdAt.length >= 16 ? createdAt.substring(0, 16) : createdAt;
}
