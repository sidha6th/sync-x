part of '../base/base_notifier.dart';

/// A mixin that provides lifecycle hooks for notifiers.
///
/// Use this mixin to add initialization and state update logic to notifiers.
/// It provides hooks for setup logic and state change notifications.
///
/// [S] is the type of state managed by the notifier.
///
/// This mixin is automatically used by [Notifier] and provides the [onInit] and [onUpdate] lifecycle methods.
mixin NotifierLifecycle<S> {
  void _initialize() => onInit();

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
  ///
  /// Example (correct usage):
  /// ```dart
  /// class MyNotifier extends Notifier<int> with NotifierLifecycle<int> {
  ///   MyNotifier() : super(0);
  ///
  ///   @override
  ///   void onInit() {
  ///     // Initialize resources, start listeners, etc.
  ///     print('Notifier initialized');
  ///   }
  /// }
  /// ```
  void onInit() {}

  /// Called when the notifier's state is updated.
  ///
  /// Override this method to perform side effects or additional logic when the state changes.
  /// This method is called after the state has been updated and listeners have been notified.
  ///
  /// [state] is the new state value after the update.
  ///
  /// Use this method for:
  /// - Logging state changes
  /// - Triggering side effects based on state changes
  /// - Updating external systems
  /// - Analytics tracking
  ///
  /// Example:
  /// ```dart
  /// class MyNotifier extends Notifier<int> with NotifierLifecycle<int> {
  ///   MyNotifier() : super(0);
  ///
  ///   @override
  ///   void onUpdated(int state) {
  ///     // Log state changes
  ///     print('State updated to: $state');
  ///
  ///     // Trigger side effects
  ///     if (state > 10) {
  ///       _showNotification('High value reached!');
  ///     }
  ///   }
  /// }
  /// ```
  void onUpdate(S state) {}
}
