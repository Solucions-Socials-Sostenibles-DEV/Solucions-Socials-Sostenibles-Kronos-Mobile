import 'package:flutter/foundation.dart';

class Logger {
  Logger._();

  static void d(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null) debugPrint('  stack: $stackTrace');
  }
}


