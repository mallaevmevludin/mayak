import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/view_state.dart';
import 'app_empty_state.dart';

/// Универсальный рендер [ViewState]: спиннер / контент / пустое состояние /
/// ошибка с кнопкой «Повторить». Убирает копипаст веток loading/empty/error
/// по экранам.
class AsyncStateView<T> extends StatelessWidget {
  final ViewState<T> state;

  /// Построение UI при наличии данных.
  final Widget Function(BuildContext context, T data) onData;

  /// Повтор запроса (для состояний ошибки и пустоты, если уместно).
  final VoidCallback? onRetry;

  // Тексты пустого состояния по умолчанию.
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.onData,
    this.onRetry,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Пока пусто',
    this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      LoadingViewState<T>() => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      DataViewState<T>(:final data) => onData(context, data),
      EmptyViewState<T>() => AppEmptyState(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
      ErrorViewState<T>(:final message) => AppEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Не удалось загрузить',
          subtitle: message,
          actionLabel: onRetry != null ? 'Повторить' : null,
          onAction: onRetry,
        ),
    };
  }
}
