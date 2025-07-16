import 'package:flutter/foundation.dart'
    show
        ChangeNotifier,
        describeIdentity,
        kFlutterMemoryAllocationsEnabled,
        mustCallSuper,
        protected;

part 'base_notifier.dart';

/// A concrete implementation of [BaseNotifier] that provides a default [setState] behavior.
///
/// [Notifier] updates its state and notifies listeners when [setState] is called, unless the state is unchanged and [forced] is false.
///
/// [S] is the type of state managed by the notifier.
abstract class Notifier<S> extends BaseNotifier<S> {
  /// Creates a [Notifier] with the given initial state.
  Notifier(super.state);

  @override
  @protected
  @mustCallSuper
  void setState(S newState, {bool forced = false, bool notify = true}) {
    if (_state == newState && !forced) return;
    _state = newState;
    if (notify) super.notifyListeners();
  }

  @override
  @protected
  @Deprecated('Use setState instead')
  void notifyListeners() {}
}
