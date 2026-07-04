import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// App-wide logging (Step 10 §10.3): routes every log record through
/// package:logging so call sites just get a named [Logger], mirrors each
/// record to the debug console, and best-effort appends it to a small
/// on-device file so a crash can be diagnosed after the fact without a
/// debugger attached ("краш-лог у файл на девайсі").
class AppLogger {
  const AppLogger._();

  static bool _initialized = false;
  static File? _logFile;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_handleRecord);

    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/middlemen_log.txt');
    } catch (_) {
      // No writable directory available (e.g. some test hosts) — the
      // console mirror below still works.
    }
  }

  static Logger of(String name) => Logger(name);

  static void _handleRecord(LogRecord record) {
    final line =
        '${record.time.toIso8601String()} ${record.level.name} '
        '${record.loggerName}: ${record.message}'
        '${record.error != null ? ' | error: ${record.error}' : ''}';
    debugPrint(line);

    final file = _logFile;
    if (file != null) {
      unawaited(
        file.writeAsString('$line\n', mode: FileMode.append).catchError((_) => file),
      );
    }
  }
}
