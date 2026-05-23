import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Минимальный логгер, чтобы исключить silent failures: даже когда
/// исключение «поглощается» (например, повреждённый JSON в кэше), оно
/// всё равно фиксируется в консоли разработчика с тегом и стек-трейсом.
///
/// В релизной сборке вывод глушится (debugPrint), но факт ошибки
/// сохраняется через `dart:developer.log`, который видят отладочные
/// инструменты Aurora/Flutter.
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] $message');
    }
    developer.log(message, name: tag, level: 800);
  }

  static void warn(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARN][$tag] $message${error != null ? ' :: $error' : ''}');
    }
    developer.log(message, name: tag, level: 900, error: error);
  }

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] $message${error != null ? ' :: $error' : ''}');
    }
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
