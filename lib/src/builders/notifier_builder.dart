import 'package:flutter/widgets.dart' show BuildContext, Widget, VoidCallback;
import 'package:syncx/src/builders/base_notifier_builder.dart';
import 'package:syncx/src/notifier/notifier.dart' show BaseNotifier;

/// A widget that rebuilds when the state of the provided [BaseNotifier] changes.
///
/// [NotifierBuilder] is a convenience widget for listening to a [BaseNotifier] and rebuilding
/// its child whenever the state changes, optionally using [buildWhen] to control rebuilds.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of state managed by the notifier.
final class NotifierBuilder<N extends BaseNotifier<S>, S>
    extends BaseNotifierBuilder<N, S> {
  /// Creates a [NotifierBuilder].
  ///
  /// [builder] is called to build the widget tree based on the current state.
  /// [buildWhen] is an optional predicate that determines whether to rebuild when the state changes.
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  /// [key] is the widget key.
  const NotifierBuilder({
    required Widget Function(BuildContext, S) super.builder,
    this.buildWhen,
    super.onInit,
    super.key,
  });

  /// Optional predicate to determine whether to rebuild when the state changes.
  ///
  /// If [buildWhen] returns true, the widget will rebuild. If null, always rebuilds.
  final bool Function(S previous, S current)? buildWhen;

  @override
  void whenStateChanged(S previous, S current, VoidCallback reBuild) {
    if (buildWhen?.call(previous, current) ?? true) reBuild();
  }
}
