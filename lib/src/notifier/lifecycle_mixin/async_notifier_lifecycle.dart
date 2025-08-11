part of '../base/base_notifier.dart';

/// A mixin that provides lifecycle hooks for asynchronous notifiers.
///
/// Use this mixin to add initialization and state update logic to notifiers that manage async operations.
/// It provides hooks for setup logic, async initialization, and state change notifications.
///
/// [S] is the type of data managed by the notifier.
///
/// This mixin is automatically used by [AsyncNotifier] and provides the [onInit] and [onUpdate] lifecycle methods.
/// Intended to be used with notifiers that require setup or cleanup, such as starting or cancelling streams.
mixin AsyncNotifierLifecycle<S> {
  void _initialize(void Function(AsyncState<S> state) whenCompleted) {
    onInit().then(whenCompleted);
  }

  /// Called when the notifier is first initialized and attached to the widget tree.
  ///
  /// Override this method to perform asynchronous setup, such as fetching initial data,
  /// starting listeners, or other async initialization tasks. The returned [AsyncState]
  /// is typically used to update the notifier's state.
  ///
  /// This method is automatically invoked after the notifier is created and attached to the widget tree.
  /// **Do not** call [onInit] manually from builder widget `onInit` callbacks, as this will result in duplicate initialization.
  ///
  /// Example (incorrect usage):
  /// ```dart
  /// NotifierBuilder<Notifier, State>(
  ///   // Do NOT do this:
  ///   onInit: (notifier) => notifier.onInit(),
  ///   builder: (context, state) => Text('State: $state'),
  /// )
  /// ```
  ///
  /// Example (correct usage):
  /// ```dart
  /// class MyAsyncNotifier extends AsyncNotifier<String> with AsyncNotifierLifecycle<String> {
  ///   MyAsyncNotifier() : super();
  ///
  ///   @override
  ///   Future<AsyncState<String>> onInit() async {
  ///     // Fetch initial data
  ///     final data = await _fetchData();
  ///     return AsyncState.data(data);
  ///   }
  /// }
  /// ```
  ///
  /// Returns a [Future] that completes with the new [AsyncState] for the notifier.
  Future<AsyncState<S>> onInit();

  /// Called when the notifier's async state is updated.
  ///
  /// Override this method to perform side effects or additional logic when the async state changes.
  /// This method is called after the state has been updated and listeners have been notified.
  ///
  /// [state] is the new async state value after the update.
  ///
  /// Use this method for:
  /// - Logging state changes
  /// - Triggering side effects based on async state changes
  /// - Updating external systems
  /// - Analytics tracking
  /// - Handling specific state transitions (loading → data, data → error, etc.)
  ///
  /// Example:
  /// ```dart
  /// class MyAsyncNotifier extends AsyncNotifier<String> with AsyncNotifierLifecycle<String> {
  ///   MyAsyncNotifier() : super();
  ///
  ///   @override
  ///   void onUpdated(BaseAsyncState<String> state) {
  ///     // Log state changes
  ///     print('Async state updated: ${state.runtimeType}');
  ///
  ///     // Handle specific state transitions
  ///     if (state.isLoading) {
  ///       print('Started loading data');
  ///     } else if (state.hasError) {
  ///       print('Error occurred: ${state.errorState?.message}');
  ///     } else if (state.data != null) {
  ///       print('Data loaded: ${state.data}');
  ///     }
  ///   }
  /// }
  /// ```
  void onUpdate(BaseAsyncState<S> state) {}
}
