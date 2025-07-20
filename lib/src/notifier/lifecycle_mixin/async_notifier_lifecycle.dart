part of '../base/base_notifier.dart';

/// A mixin that provides lifecycle hooks for asynchronous notifiers.
///
/// Use this mixin to add initialization and disposal logic to notifiers that manage async operations.
/// Intended to be used with notifiers that require setup or cleanup, such as starting or cancelling streams.
mixin AsyncNotifierLifecycle<S> {
  void _initialize(void Function(AsyncState<S> state) whenCompleted) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onInit().then(whenCompleted),
    );
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
  /// Returns a [Future] that completes with the new [AsyncState] for the notifier.
  @protected
  Future<AsyncState<S>> onInit();
}
