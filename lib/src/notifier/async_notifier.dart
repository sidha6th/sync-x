part of 'base/base_notifier.dart';

/// A concrete implementation of [BaseNotifier] for managing asynchronous state using [AsyncState].
///
/// [AsyncNotifier] simplifies handling loading, data, and error states for async operations
/// such as network requests, database queries, or any operation that can be in a loading,
/// success, or error state.
///
/// [S] is the type of data managed by the notifier.
///
/// This class integrates with [AsyncNotifierLifecycle] for automatic initialization
/// and provides convenient methods for transitioning between loading, data, and error states.
///
/// Example usage:
/// ```dart
/// class MyAsyncNotifier extends AsyncNotifier<String> {
///   @override
///   Future<AsyncState<String>> onInit() async {
///     // Simulate network request
///     await Future.delayed(Duration(seconds: 2));
///     return const AsyncState.data('Hello from AsyncNotifier!');
///   }
/// }
/// ```
abstract class AsyncNotifier<S> extends BaseNotifier<BaseAsyncState<S>>
    with AsyncNotifierLifecycle<S> {
  /// Creates an [AsyncNotifier] with initial data.
  ///
  /// [state] is the initial data to set. The notifier starts with the provided data state.
  ///
  /// Example:
  /// ```dart
  /// // Start with data state
  /// AsyncNotifier<String>.withData('Initial data')
  /// ```
  AsyncNotifier.withData(S data) : super(AsyncState.data(data)) {
    _initialize(setState);
  }

  /// Creates an [AsyncNotifier] that starts in the loading state.
  ///
  /// Use this constructor when you want the notifier to start in a loading state
  /// and then transition to data or error state based on async operations.
  ///
  /// Example:
  /// ```dart
  /// // Start with loading state
  /// AsyncNotifier<String>()
  /// ```
  AsyncNotifier() : super(const AsyncState.loading()) {
    _initialize(setState);
  }

  /// Transitions the notifier to the loading state.
  ///
  /// Use this when starting an async operation to indicate that the data is being fetched.
  ///
  /// Example:
  /// ```dart
  /// void fetchData() {
  ///   setLoading();
  ///   // Perform async operation...
  /// }
  /// ```
  @protected
  void setLoading() => setState(state.toLoading(), forced: true);

  /// Transitions the notifier to the data state with the given [data].
  ///
  /// [data] is the successful result of the async operation.
  /// [forced] (default: false): Forces the state update even if the value hasn't changed.
  /// [notify] (default: true): Controls whether listeners are notified and the UI is rebuilt.
  ///
  /// Use this when an async operation completes successfully.
  ///
  /// Example:
  /// ```dart
  /// void onDataReceived(String data) {
  ///   setData(data);
  /// }
  ///
  /// void updateSilently(String data) {
  ///   setData(data, notify: false); // Update without notifying listeners
  /// }
  ///
  /// void forceUpdate(String data) {
  ///   setData(data, forced: true); // Updates the state bypassing the equality check
  /// }
  /// ```
  @protected
  void setData(
    S data, {
    bool forced = false,
    bool notify = true,
  }) {
    return setState(
      notify: notify,
      forced: forced,
      state.toData(data),
    );
  }

  /// Transitions the notifier to the error state with the given error information.
  ///
  /// [error] is the error object or exception that occurred.
  /// [message] is an optional error message for display.
  /// [stackTrace] is an optional stack trace for debugging.
  ///
  /// Use this when an async operation fails.
  ///
  /// Example:
  /// ```dart
  /// void onError(Exception error) {
  ///   setError(error, message: 'Failed to fetch data');
  /// }
  /// ```
  @protected
  void setError(
    Object error, {
    String? message,
    StackTrace? stackTrace,
  }) {
    return setState(
      state.toError(
        error,
        message: message,
        stackTrace: stackTrace,
      ),
      forced: true,
    );
  }

  /// Updates the state with the given [next] state.
  ///
  /// [next] is the new state to set.
  /// [notify] (default: true): Controls whether listeners are notified and the UI is rebuilt.
  /// [forced] (default: false): Forces the state update even if the value hasn't changed.
  /// [equalityCheck] (optional): Custom function to determine if state has changed.
  ///
  /// This method provides fine-grained control over state updates and listener notifications.
  ///
  /// Example:
  /// ```dart
  /// void updateState(BaseAsyncState<String> newState) {
  ///   setState(newState, notify: true, forced: false);
  /// }
  /// ```
  @protected
  void setState(
    BaseAsyncState<S> next, {
    bool notify = true,
    bool forced = false,
    bool Function(S? curr, S? next)? equalityCheck,
  }) {
    _setState(
      next,
      notify: notify,
      forced: forced,
      onUpdate: onUpdate,
      equalityCheck: (curr, next) =>
          (equalityCheck?.call(curr.data, next.data) ??
              this.stateEqualityCheck(curr, next)) &&
          curr == next,
    );
  }

  /// Custom equality check for async states.
  ///
  /// Compares the data fields of two async states to determine if they are equal.
  /// Override this method to provide custom equality logic.
  ///
  /// [curr] is the current state.
  /// [next] is the new state.
  ///
  /// Returns true if the states are considered equal, false otherwise.
  @override
  @protected
  bool stateEqualityCheck(BaseAsyncState<S> curr, BaseAsyncState<S> next) =>
      curr.data == next.data;
}
