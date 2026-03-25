import 'package:flutter/foundation.dart';

/// Logger simples com níveis e timestamp.
/// Em produção (kReleaseMode) suprime [debug].
class AppLogger {
  AppLogger._();

  static String _ts() => DateTime.now().toIso8601String();

  static void debug(String tag, String msg) {
    if (!kReleaseMode) {
      debugPrint('[DEBUG][${_ts()}][$tag] $msg');
    }
  }

  static void info(String tag, String msg) {
    debugPrint('[INFO][${_ts()}][$tag] $msg');
  }

  static void warn(String tag, String msg) {
    debugPrint('[WARN][${_ts()}][$tag] $msg');
  }

  static void error(String tag, String msg, [Object? err, StackTrace? st]) {
    debugPrint('[ERROR][${_ts()}][$tag] $msg');
    if (err != null) debugPrint('  ↳ $err');
    if (st != null && !kReleaseMode) debugPrint('  ↳ $st');
  }
}