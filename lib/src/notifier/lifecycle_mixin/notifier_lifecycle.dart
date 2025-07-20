part of '../base/base_notifier.dart';

/// A mixin that provides lifecycle hooks for notifiers.
///
/// Use this mixin to add initialization and disposal logic to notifiers.
/// Intended to be used with notifiers that require setup or cleanup, such as resource allocation or event listeners.
mixin NotifierLifecycle {
  void _initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onInit());
  }

  @protected

  /// Called when the notifier is initialized and attached to the widget tree.
  ///
  /// Override this method to perform setup logic, such as initializing resources
  /// or starting listeners.
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
  void onInit() {}
}
