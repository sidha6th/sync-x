part of 'base/base_notifier.dart';

/// A concrete implementation of [BaseNotifier] that provides a default [setState] behavior.
///
/// [Notifier] updates its state and notifies listeners when [setState] is called, unless the state is unchanged and [forced] is false.
///
/// [S] is the type of state managed by the notifier.
///
/// This class integrates with [NotifierLifecycle] for automatic initialization
/// and provides convenient methods for state management with fine-grained control.
///
/// Example usage:
/// ```dart
/// class MyNotifier extends Notifier<int> {
///   MyNotifier() : super(0);
///
///   void increment() => setState(state + 1);
///   void incrementSilently() => setState(state + 1, notify: false);
/// }
/// ```
abstract class Notifier<S> extends BaseNotifier<S> with NotifierLifecycle<S> {
  /// Creates a [Notifier] with the given initial state.
  ///
  /// [state] is the initial state value for the notifier.
  ///
  /// Example:
  /// ```dart
  /// class CounterNotifier extends Notifier<int> {
  ///   CounterNotifier() : super(0); // Start with initial state of 0
  /// }
  /// ```
  Notifier(super.state) {
    _initialize();
  }

  /// Updates the state with the given [next] state.
  ///
  /// [next] is the new state value to set.
  /// [notify] (default: true): Controls whether listeners are notified and the UI is rebuilt.
  /// [forced] (default: false): Forces the state update even if the value hasn't changed, useful for mutating iterable state.
  /// [equalityCheck] (optional): Custom function to determine if state has changed.
  ///
  /// This method provides fine-grained control over state updates and listener notifications.
  /// By default, it uses basic equality checking (== and identical) to determine if the state has changed.
  ///
  /// Example:
  /// ```dart
  /// void increment() => setState(state + 1);
  ///
  /// void updateSilently(int newValue) {
  ///   setState(newValue, notify: false); // Update without notifying listeners
  /// }
  ///
  /// void forceUpdate(int newValue) {
  ///   setState(newValue, forced: true); // Updates the state bypassing the equality check
  /// }
  ///
  /// void customEqualityUpdate(int newValue) {
  ///   setState(newValue, equalityCheck: (curr, next) => curr.abs() == next.abs());
  /// }
  /// ```
  @protected
  void setState(
    S next, {
    bool notify = true,
    bool forced = false,
    bool Function(S curr, S next)? equalityCheck,
  }) {
    _setState(
      next,
      notify: notify,
      forced: forced,
      onUpdate: onUpdate,
      equalityCheck: equalityCheck,
    );
  }
}
