part of 'base/base_notifier.dart';

/// A concrete implementation of [BaseNotifier] for managing asynchronous state using [AsyncState].
///
/// [AsyncNotifier] simplifies handling loading, data, and error states for async operations.
/// It integrates with [AsyncNotifierLifecycle] for lifecycle management.
///
/// [S] is the type of data managed by the notifier.
abstract class AsyncNotifier<S> extends BaseNotifier<AsyncState<S>>
    with AsyncNotifierLifecycle<S> {
  /// Creates an [AsyncNotifier] with an optional initial [state].
  ///
  /// If [state] is null, the notifier starts in the loading state.
  /// Otherwise, it starts with the provided data state.
  AsyncNotifier([S? state])
    : super(
        state == null ? const AsyncState.loading() : AsyncState.data(state),
      ) {
    _initialize();
  }
}
