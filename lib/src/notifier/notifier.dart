part of 'base/base_notifier.dart';

/// A concrete implementation of [BaseNotifier] that provides a default [setState] behavior.
///
/// [Notifier] updates its state and notifies listeners when [setState] is called, unless the state is unchanged and [forced] is false.
///
/// [S] is the type of state managed by the notifier.
abstract class Notifier<S> extends BaseNotifier<S> with NotifierLifecycle {
  /// Creates a [Notifier] with the given initial state.
  Notifier(super.state) {
    _initialize();
  }
}
