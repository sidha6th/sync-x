import 'package:flutter/foundation.dart'
    show
        kFlutterMemoryAllocationsEnabled,
        ChangeNotifier,
        protected,
        mustCallSuper,
        describeIdentity;
import 'package:meta/meta.dart' show internal;
import 'package:syncx/src/utils/models/async_state.dart';
import 'package:syncx/src/utils/models/base/base_async_state.dart';

part '../async_notifier.dart';
part '../lifecycle_mixin/async_notifier_lifecycle.dart';
part '../lifecycle_mixin/notifier_lifecycle.dart';
part '../notifier.dart';

/// The base class show ChangeNotifier, VoidCallback, describeIdentity, kFlutterMemoryAllocationsEnabled, mustCallSuper, protected intended to be extended by more specific notifier implementations.
///
/// [S] is the type of state managed by the notifier.
@internal
abstract class BaseNotifier<S extends Object?> with ChangeNotifier {
  /// Creates a [BaseNotifier] with the given initial state.
  ///
  /// If [kFlutterMemoryAllocationsEnabled] is true, notifies Flutter's memory allocation tracker.
  BaseNotifier(this._state) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  /// The current state held by the notifier.
  S _state;

  /// Returns the current state.
  @protected
  S get state => _state;

  /// Updates the state to [newState].
  ///
  /// [forced] can be set to true to force the update even if the state is unchanged.
  /// [notify] controls whether listeners are notified after the update.
  @protected
  @mustCallSuper
  void setState(S newState, {bool forced = false, bool notify = true}) {
    if (_state != newState || forced) _state = newState;
    if (notify) super.notifyListeners();
  }

  @override
  @protected
  @Deprecated('This will throw a unsupported error, Use setState instead')
  Never notifyListeners() {
    throw UnsupportedError(
      'Direct calls to notifyListeners() are not allowed.'
      'Use setState() to update state and notify listeners.',
    );
  }

  @override
  String toString() => '${describeIdentity(this)}($_state)';
}
