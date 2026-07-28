import 'package:shared_preferences/shared_preferences.dart';

class NewsStateService {
  static final NewsStateService instance = NewsStateService._();
  NewsStateService._();

  static const _kReadSet = 'news_read';
  static const _kDismissedSet = 'news_dismissed';

  final Set<String> _read = {};
  final Set<String> _dismissed = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _read.clear();
    _read.addAll(prefs.getStringList(_kReadSet) ?? []);
    _dismissed.clear();
    _dismissed.addAll(prefs.getStringList(_kDismissedSet) ?? []);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReadSet, _read.toList());
    await prefs.setStringList(_kDismissedSet, _dismissed.toList());
  }

  bool isRead(String id) => _read.contains(id);

  bool isDismissed(String id) => _dismissed.contains(id);

  Future<void> markAsRead(String id) async {
    if (_read.add(id)) {
      await save();
    }
  }

  Future<void> dismiss(String id) async {
    if (_dismissed.add(id)) {
      await save();
    }
  }

  Future<void> undismiss(String id) async {
    if (_dismissed.remove(id)) {
      await save();
    }
  }

  Future<void> dismissMultiple(Iterable<String> ids) async {
    var changed = false;
    for (final id in ids) {
      if (_dismissed.add(id)) {
        changed = true;
      }
    }
    if (changed) {
      await save();
    }
  }

  Future<void> undismissMultiple(Iterable<String> ids) async {
    var changed = false;
    for (final id in ids) {
      if (_dismissed.remove(id)) {
        changed = true;
      }
    }
    if (changed) {
      await save();
    }
  }
}
