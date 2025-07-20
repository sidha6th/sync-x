import 'package:flutter/widgets.dart' show Widget, VoidCallback;
import 'package:syncx/src/builders/base/base_notifier_builder.dart';
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;

/// A widget that listens to state changes from a [BaseNotifier] and triggers side effects.
///
/// [NotifierListener] does not rebuild its child when the state changes, but instead
/// calls the [listener] callback for side effects, optionally using [listenWhen] to control when to listen.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of state managed by the notifier.
class NotifierListener<N extends BaseNotifier<S>, S>
    extends BaseNotifierBuilder<N, S> {
  /// Creates a [NotifierListener].
  ///
  /// [child] is the static child widget.
  /// [listener] is called for side effects when the state changes.
  /// [listenWhen] is an optional predicate that determines whether to call [listener] when the state changes.
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
  /// Example (incorrect usage):
  /// ```dart
  /// NotifierListener<Notifier, State>(
  ///   // Do NOT do this:
  ///   onInit: (notifier) => notifier.onInit(),
  ///   listener: (context, state) {...},
  ///   child: ...,
  /// )
  /// ```
  ///
  /// [key] is the widget key.
  const NotifierListener({
    required Widget super.child,
    required this.listener,
    this.listenWhen,
    super.notifier,
    super.onInit,
    super.key,
  });

  /// Callback for side effects when the state changes.
  final void Function(S state) listener;

  /// Optional predicate to determine whether to call [listener] when the state changes.
  ///
  /// If [listenWhen] returns true, [listener] will be called. If null, always calls [listener].
  final bool Function(S previous, S current)? listenWhen;

  @override
  void whenStateChanged(S previous, S current, VoidCallback reBuild) {
    if (listenWhen?.call(previous, current) ?? true) listener(current);
  }
}
