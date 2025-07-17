part of '../base/base_notifier.dart';

/// A mixin that provides lifecycle hooks for asynchronous notifiers.
///
/// Use this mixin to add initialization and disposal logic to notifiers that manage async operations.
/// Intended to be used with notifiers that require setup or cleanup, such as starting or cancelling streams.
mixin AsyncNotifierLifecycle<S> {
  void _initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onInit());
  }

  @protected

  /// Called when the notifier is initialized.
  /// Override this to perform async setup, such as fetching data or starting listeners.
  Future<AsyncState<S>> onInit();
}
