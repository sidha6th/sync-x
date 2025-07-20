import 'package:flutter/widgets.dart'
    show StatefulWidget, Widget, BuildContext, VoidCallback, State, SizedBox;
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/extensions/build_context_extensions.dart';

/// A base class for building widgets that listen to a [BaseNotifier] and rebuild
/// when its state changes. Intended to be extended by more specific notifier builders.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of state managed by the notifier.
abstract class BaseNotifierBuilder<N extends BaseNotifier<S>, S>
    extends StatefulWidget {
  /// Creates a [BaseNotifierBuilder].
  ///
  /// [notifier] is the instance of [BaseNotifier] to listen to. If null, it will be obtained from the nearest [Provider].
  /// 
  /// [child] is an optional static child widget.
  /// 
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
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
  /// [builder] is a function that builds the widget tree based on the current state.
  const BaseNotifierBuilder({
    this.notifier,
    this.builder,
    this.onInit,
    this.child,
    super.key,
  });

  /// The [BaseNotifier] instance to listen to. If null, it will be obtained from the nearest [Provider].
  final N? notifier;

  /// An optional static child widget.
  final Widget? child;

  /// An optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
  final void Function(N notifier)? onInit;

  /// A function that builds the widget tree based on the current state.
  final Widget Function(BuildContext context, S state)? builder;

  /// Called when the notifier's state changes.
  ///
  /// Implement this to determine when to trigger a rebuild based on state changes.
  /// [previous] is the previous state, [current] is the new state, and [reBuild] is a callback to trigger a rebuild.
  void whenStateChanged(S previous, S current, VoidCallback reBuild);

  @override
  State<StatefulWidget> createState() => _BaseNotifierBuilderState<N, S>();
}

/// The state class for [BaseNotifierBuilder]. Handles listening to the notifier and rebuilding when needed.
class _BaseNotifierBuilderState<N extends BaseNotifier<S>, S>
    extends State<BaseNotifierBuilder<N, S>> {
  /// The notifier instance being listened to. Initialized from the widget or the nearest Provider.
  late N notifier = widget.notifier ?? context.get<N>();

  /// The previous state, used to compare with the current state on changes.
  late S _previous = notifier.state;

  @override
  void initState() {
    super.initState();
    notifier.addListener(_whenStateChanged);
    widget.onInit?.call(notifier);
  }

  @override
  void didUpdateWidget(covariant BaseNotifierBuilder<N, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the notifier instance changes, update the listener.
    if (widget.notifier == null || widget.notifier == notifier) return;
    notifier = widget.notifier!;
  }

  @override
  Widget build(BuildContext context) {
    // Build using the builder function if provided, otherwise use the child or an empty box.
    return widget.builder?.call(context, _previous) ??
        widget.child ??
        const SizedBox.shrink();
  }

  @override
  void dispose() {
    notifier.removeListener(_whenStateChanged);
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  /// Internal callback when the notifier's state changes.
  void _whenStateChanged() {
    widget.whenStateChanged(_previous, notifier.state, _reBuild);
    _previous = notifier.state;
  }

  /// Triggers a rebuild of the widget.
  void _reBuild() => setState(() {});
}
