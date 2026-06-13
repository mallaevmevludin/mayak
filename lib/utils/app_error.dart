import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';

/// Единая модель пользовательской ошибки: превращает технические исключения
/// (Supabase, сеть, таймауты) в понятные сообщения на русском.
///
/// Использование:
/// ```dart
/// try {
///   await repo.doSomething();
/// } catch (e, s) {
///   final err = AppError.from(e, s);
///   TopNotification.show(context, err.message);
/// }
/// ```
class AppError {
  /// Сообщение для пользователя.
  final String message;

  /// Исходная ошибка (для логов/отчётов), не показывается пользователю.
  final Object? cause;

  const AppError(this.message, {this.cause});

  static const String _network =
      'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
  static const String _timeout =
      'Сервер слишком долго не отвечает. Попробуйте ещё раз.';
  static const String _generic = 'Что-то пошло не так. Попробуйте позже.';

  /// Преобразует любое исключение в [AppError] и логирует его.
  factory AppError.from(Object error, [StackTrace? stackTrace]) {
    AppLogger.error('Handled error', error: error, stackTrace: stackTrace);

    if (error is AppError) return error;

    // Сеть
    if (error is SocketException || error is HttpException) {
      return const AppError(_network);
    }
    if (error is TimeoutException) {
      return const AppError(_timeout);
    }

    // Supabase
    if (error is AuthException) {
      return AppError(_mapAuthMessage(error.message), cause: error);
    }
    if (error is PostgrestException) {
      return AppError(_mapPostgrestMessage(error), cause: error);
    }
    if (error is StorageException) {
      return AppError(
        'Не удалось загрузить файл. Попробуйте ещё раз.',
        cause: error,
      );
    }

    return AppError(_generic, cause: error);
  }

  static String _mapAuthMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Неверный e-mail или пароль.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Подтвердите e-mail, чтобы войти.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already')) {
      return 'Пользователь с таким e-mail уже зарегистрирован.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Слишком много попыток. Подождите немного и попробуйте снова.';
    }
    return 'Ошибка авторизации. Попробуйте ещё раз.';
  }

  static String _mapPostgrestMessage(PostgrestException e) {
    // 23505 — нарушение уникальности
    if (e.code == '23505') {
      return 'Такая запись уже существует.';
    }
    // RLS / доступ запрещён
    if (e.code == '42501' || (e.message.toLowerCase().contains('row-level'))) {
      return 'Недостаточно прав для этого действия.';
    }
    return _generic;
  }

  @override
  String toString() => 'AppError($message)';
}
