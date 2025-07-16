part of 'notifier.dart';

/// The base class for all notifiers in the SyncX package.
///
/// [BaseNotifier] provides a state container with change notification capabilities.
/// It is intended to be extended by more specific notifier implementations.
///
/// [S] is the type of state managed by the notifier.
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
  S get state => _state;

  /// Updates the state to [newState].
  ///
  /// [forced] can be set to true to force the update even if the state is unchanged.
  /// [notify] controls whether listeners are notified after the update.
  void setState(S newState, {bool forced = false, bool notify = true});

  @override
  String toString() => '${describeIdentity(this)}($_state)';
}
