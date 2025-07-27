import 'dart:ui';

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

/// The base class for all notifier implementations in SyncX.
///
/// [BaseNotifier] extends [ChangeNotifier] and provides a foundation for state management
/// with automatic listener notification. It enforces the use of [setState] for state updates
/// and prevents direct calls to notifyListeners.
///
/// [S] is the type of state managed by the notifier.
///
/// This class is intended to be extended by more specific notifier implementations
/// such as [Notifier] and [AsyncNotifier].
///
/// Example usage:
/// ```dart
/// class MyNotifier extends BaseNotifier<int> {
///   MyNotifier() : super(0);
///
///   void increment() => setState(state + 1);
/// }
/// ```
@internal
abstract class BaseNotifier<S extends Object?> extends _RootBaseNotifier<S> {
  /// Creates a [BaseNotifier] with the given initial [state].
  BaseNotifier(super.state);

  /// Overrides [notifyListeners] to prevent direct calls.
  ///
  /// This method is deprecated and will throw an [UnsupportedError] if called directly.
  ///
  /// Use [setState] instead to update state and notify listeners automatically.
  ///
  /// This ensures that state updates always go through the proper [setState] method,
  /// maintaining consistency and preventing potential bugs.
  @override
  @protected
  @Deprecated('This will throw an unsupported error. Use setState instead')
  Never notifyListeners() {
    throw UnsupportedError(
      'Direct calls to notifyListeners() are not allowed. '
      'Use setState() to update state and notify listeners.',
    );
  }

  /// Adds a listener to be notified when the state changes.
  ///
  /// [listener] is the callback function to be called when the state changes.
  ///
  /// This method is protected and should be used by the framework, not directly by users.
  @override
  @protected
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  /// Removes a previously added listener.
  ///
  /// [listener] is the callback function to remove.
  ///
  /// This method is protected and should be used by the framework, not directly by users.
  @override
  @protected
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }

  /// Returns a string representation of the notifier.
  ///
  /// Includes the notifier's identity and current state for debugging purposes.
  @override
  String toString() => '${describeIdentity(this)}($_state)';
}

/// Internal base class that provides the core functionality for state management.
///
/// [_RootBaseNotifier] extends [ChangeNotifier] and provides the fundamental state management
/// capabilities including state storage, state updates via [setState], and listener management.
///
/// [S] is the type of state managed by the notifier.
abstract class _RootBaseNotifier<S extends Object?> with ChangeNotifier {
  /// Creates a [_RootBaseNotifier] with the given initial [state].
  ///
  /// If [kFlutterMemoryAllocationsEnabled] is true, notifies Flutter's memory allocation tracker
  /// for debugging and profiling purposes.
  _RootBaseNotifier(this._state) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  /// The current state held by the notifier.
  S _state;

  /// Returns the current state.
  ///
  /// This getter provides read-only access to the current state.
  /// To modify the state, use [setState].
  @protected
  S get state => _state;

  /// Updates the state to [newState] and optionally notifies listeners.
  ///
  /// [newState] is the new state value to set.
  /// [forced] can be set to true to force the update even if the state is unchanged.
  ///   This is useful for manipulating iterable state where the reference might not change.
  /// [notify] controls whether listeners are notified after the update.
  ///   Set to false if you want to batch multiple state changes.
  ///
  /// Example:
  /// ```dart
  /// // Normal state update
  /// setState(newValue);
  ///
  /// // Force update even if value hasn't changed
  /// setState(newValue, forced: true);
  ///
  /// // Update without notifying listeners
  /// setState(newValue, notify: false);
  /// ```
  @protected
  @mustCallSuper
  void setState(S newState, {bool forced = false, bool notify = true}) {
    if (_state != newState || forced) _state = newState;
    if (notify) super.notifyListeners();
  }
}
