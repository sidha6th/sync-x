import 'package:flutter/widgets.dart' show Widget, BuildContext, VoidCallback;
import 'package:syncx/src/builders/base_notifier_builder.dart';
import 'package:syncx/src/notifier/notifier.dart' show BaseNotifier;

/// A widget that both rebuilds and listens to state changes from a [BaseNotifier].
///
/// [NotifierConsumer] allows you to rebuild the widget tree and perform side effects
/// in response to state changes, using [buildWhen] and [listenWhen] to control behavior.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of state managed by the notifier.
final class NotifierConsumer<N extends BaseNotifier<S>, S>
    extends BaseNotifierBuilder<N, S> {
  /// Creates a [NotifierConsumer].
  ///
  /// [builder] is called to build the widget tree based on the current state.
  /// [listener] is called for side effects when the state changes.
  /// [buildWhen] is an optional predicate that determines whether to rebuild when the state changes.
  /// [listenWhen] is an optional predicate that determines whether to call [listener] when the state changes.
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  /// [key] is the widget key.
  const NotifierConsumer({
    required Widget Function(BuildContext, S) super.builder,
    required this.listener,
    this.buildWhen,
    this.listenWhen,
    super.onInit,
    super.key,
  });

  /// Callback for side effects when the state changes.
  final void Function(S state) listener;

  /// Optional predicate to determine whether to rebuild when the state changes.
  ///
  /// If [buildWhen] returns true, the widget will rebuild. If null, always rebuilds.
  final bool Function(S previous, S current)? buildWhen;

  /// Optional predicate to determine whether to call [listener] when the state changes.
  ///
  /// If [listenWhen] returns true, [listener] will be called. If null, always calls [listener].
  final bool Function(S previous, S current)? listenWhen;

  @override
  void whenStateChanged(S previous, S current, VoidCallback reBuild) {
    if (buildWhen?.call(previous, current) ?? true) reBuild();
    if (listenWhen?.call(previous, current) ?? true) listener(current);
  }
}
