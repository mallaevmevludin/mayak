import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// Тонкая обёртка над Supabase Realtime. Подписывается на изменения в БД и
/// дёргает колбэки. Изменения «схлопываются» дебаунсом, чтобы серия событий
/// (например, пачка лайков) не вызывала шквал перезагрузок.
///
/// Требует, чтобы таблицы были добавлены в публикацию `supabase_realtime`
/// (см. миграцию `..._follows_notifications_realtime.sql`).
///
/// Используется только в боевом режиме (не в mock).
class RealtimeService {
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _feedChannel;
  RealtimeChannel? _notificationsChannel;
  Timer? _feedDebounce;

  /// Подписка на изменения ленты (посты/лайки/комментарии). [onChange]
  /// вызывается после небольшого дебаунса при любом релевантном событии.
  void subscribeToFeed({required void Function() onChange}) {
    unsubscribeFromFeed();

    void schedule(PostgresChangePayload payload) {
      AppLogger.debug('Realtime feed event: ${payload.eventType}');
      _feedDebounce?.cancel();
      _feedDebounce = Timer(const Duration(milliseconds: 600), onChange);
    }

    _feedChannel = _client.channel('public:feed')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'posts',
        callback: schedule,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'post_likes',
        callback: schedule,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: schedule,
      )
      ..subscribe();
  }

  /// Подписка на новые уведомления для конкретного пользователя.
  void subscribeToNotifications({
    required String userId,
    required void Function(PostgresChangePayload payload) onInsert,
  }) {
    unsubscribeFromNotifications();

    _notificationsChannel = _client.channel('public:notifications:$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: onInsert,
      )
      ..subscribe();
  }

  void unsubscribeFromFeed() {
    _feedDebounce?.cancel();
    _feedDebounce = null;
    final ch = _feedChannel;
    if (ch != null) {
      _client.removeChannel(ch);
      _feedChannel = null;
    }
  }

  void unsubscribeFromNotifications() {
    final ch = _notificationsChannel;
    if (ch != null) {
      _client.removeChannel(ch);
      _notificationsChannel = null;
    }
  }

  void dispose() {
    unsubscribeFromFeed();
    unsubscribeFromNotifications();
  }
}
