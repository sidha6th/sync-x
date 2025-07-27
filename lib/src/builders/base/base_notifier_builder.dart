// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart'
    show StatefulWidget, Widget, BuildContext, VoidCallback, State, SizedBox;
import 'package:meta/meta.dart' show internal;
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/extensions/build_context_extensions.dart';

/// A base widget for listening to a [BaseNotifier] and rebuilding when its state changes.
///
/// [BaseNotifierBuilder] is intended to be extended by more specific notifier builders, such as [NotifierBuilder] or [AsyncNotifierBuilder].
/// It manages the lifecycle of the notifier, listens for state changes, and provides hooks for rebuilding and initialization.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of state managed by the notifier.
@internal
abstract class BaseNotifierBuilder<N extends BaseNotifier<S>, S extends Object?>
    extends StatefulWidget {
  /// Creates a [BaseNotifierBuilder].
  ///
  /// [notifier] provides the [BaseNotifier] instance to listen to. If null, the nearest [Provider] is used.
  /// [builder] is called to build the widget tree based on the current state.
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  /// [child] is an optional static child widget.
  /// [key] is the widget key.
  ///
  const BaseNotifierBuilder({
    this.notifier,
    this.builder,
    this.onInit,
    this.child,
    super.key,
  });

  /// Provides the [BaseNotifier] instance to listen to. If null, the nearest [Provider] is used.
  final N Function()? notifier;

  /// An optional static child widget to display if [builder] is not provided.
  final Widget? child;

  /// An optional callback invoked with the notifier when the widget is initialized.
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

/// State class for [BaseNotifierBuilder].
///
/// Handles listening to the notifier, managing state, and triggering rebuilds when needed.
class _BaseNotifierBuilderState<N extends BaseNotifier<S>, S>
    extends State<BaseNotifierBuilder<N, S>> {
  /// The notifier instance being listened to. Initialized from the widget or the nearest Provider.
  late N notifier = widget.notifier?.call() ?? context.get<N>();

  /// The previous state, used to compare with the current state on changes.
  late S _previous = notifier.state;

  @override
  void initState() {
    super.initState();
    _addListener();
    widget.onInit?.call(notifier);
  }

  @override
  void didUpdateWidget(covariant BaseNotifierBuilder<N, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the notifier instance changes, update the listener.
    final newNotifier = widget.notifier?.call();
    if (newNotifier == null || newNotifier == notifier) return;
    _removeListener();
    notifier = newNotifier;
    _addListener();
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
    _removeListener();
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

  void _addListener() => notifier.addListener(_whenStateChanged);
  void _removeListener() => notifier.removeListener(_whenStateChanged);
}
