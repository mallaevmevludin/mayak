import 'app_error.dart';

/// Единое состояние асинхронного экрана: загрузка / данные / пусто / ошибка.
/// Заменяет разрозненные `isLoading` + ручные проверки `isEmpty` по экранам.
///
/// Пример:
/// ```dart
/// ViewState<List<Post>> state = const LoadingViewState();
/// // ...
/// state = posts.isEmpty
///     ? const EmptyViewState()
///     : DataViewState(posts);
/// ```
sealed class ViewState<T> {
  const ViewState();

  bool get isLoading => this is LoadingViewState<T>;

  /// Данные, если состояние — [DataViewState], иначе null.
  T? get dataOrNull => switch (this) {
        DataViewState<T>(:final data) => data,
        _ => null,
      };
}

/// Идёт первичная загрузка.
class LoadingViewState<T> extends ViewState<T> {
  const LoadingViewState();
}

/// Есть данные.
class DataViewState<T> extends ViewState<T> {
  final T data;
  const DataViewState(this.data);
}

/// Запрос успешен, но данных нет (пустой список и т.п.).
class EmptyViewState<T> extends ViewState<T> {
  const EmptyViewState();
}

/// Ошибка. [error] уже содержит готовое сообщение для пользователя.
class ErrorViewState<T> extends ViewState<T> {
  final AppError error;
  const ErrorViewState(this.error);

  String get message => error.message;
}
