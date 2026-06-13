import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Лёгкий логгер без внешних зависимостей. В отладке пишет в консоль через
/// `dart:developer`; в релизе сообщения уровня debug/info подавляются, а
/// ошибки остаются (их позже можно перенаправить в Sentry/Crashlytics —
/// см. [AppLogger.onError]).
class AppLogger {
  AppLogger._();

  /// Хук для прод-репортинга ошибок (например, Sentry). Если задан —
  /// вызывается на каждый [AppLogger.error].
  static void Function(Object error, StackTrace? stack, String? context)?
      onError;

  static void debug(String message, {String name = 'app'}) {
    if (kDebugMode) {
      developer.log(message, name: name, level: 500);
    }
  }

  static void info(String message, {String name = 'app'}) {
    if (kDebugMode) {
      developer.log(message, name: name, level: 800);
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'app',
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) {
      onError?.call(error, stackTrace, message);
    }
  }
}
