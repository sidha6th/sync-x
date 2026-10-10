// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'
    show BuildContext, SizedBox, State, StatefulWidget, Widget;
import 'package:provider/provider.dart' show SelectContext;
import 'package:provider/single_child_widget.dart'
    show SingleChildStatefulWidget, SingleChildState;
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/extensions/build_context_extensions.dart';
import 'package:syncx/src/utils/type.dart';

part '../sync/notifier_builder.dart';
part '../sync/notifier_consumer.dart';
part '../sync/notifier_listener.dart';

/// Returns its argument, used as a selector that depends on identity alone.
T _identity<T>(T value) => value;

/// Base abstract class for creating notifier-based widgets that can build, listen, and consume.
///
/// This class provides the foundation for all notifier widgets in SyncX. It combines
/// building, listening, and initialization capabilities in a single widget.
///
/// **Features:**
/// - **Building**: Render UI based on notifier state changes
/// - **Listening**: React to state changes without rebuilding
/// - **Initialization**: Execute code when the widget is first created
/// - **Conditional Logic**: Control when to rebuild or listen using `buildWhen` and `listenWhen`
///
abstract class _BaseNotifierBuilder<N extends BaseNotifier<S>,
    S extends Object?> extends SingleChildStatefulWidget {
  /// Creates a base notifier builder.
  ///
  /// **Parameters:**
  /// - `builder`: Optional function to build the widget based on state and child
  /// - `buildWhen`: Optional function to determine if the widget should rebuild
  /// - `listenWhen`: Optional function to determine if the listener should be called
  /// - `listener`: Optional function to execute when state changes (without rebuilding)
  /// - `onInit`: Optional function to execute when the widget is first created
  /// - `child`: Optional child widget to pass to the builder
  /// - `key`: Optional key for the widget
  const _BaseNotifierBuilder({
    this.builder,
    this.buildWhen,
    this.listenWhen,
    this.listener,
    this.onInit,
    super.child,
    super.key,
  });

  /// Function to execute when state changes without triggering a rebuild.
  ///
  /// This is useful for side effects like navigation, showing dialogs, or logging.
  /// The listener is called whenever the state changes and `listenWhen` returns true.
  ///
  /// **Example:**
  /// ```dart
  /// NotifierListener<CounterNotifier, int>(
  ///   listener: (state) {
  ///     if (state > 10) {
  ///       ScaffoldMessenger.of(context).showSnackBar(
  ///         SnackBar(content: Text('Count exceeded 10!'))
  ///       );
  ///     }
  ///   },
  ///   child: MyWidget(),
  /// )
  /// ```
  final void Function(S state)? listener;

  /// Function to execute when the widget is first created.
  ///
  /// This is called once during `initState` and is useful for initializing
  /// the notifier or performing one-time setup operations.
  ///
  /// **Example:**
  /// ```dart
  /// NotifierBuilder<DataNotifier, List<String>>(
  ///   onInit: (notifier) {
  ///     notifier.loadData(); // Load data when widget is created
  ///   },
  ///   builder: (context, data, child) => ListView.builder(
  ///     itemCount: data.length,
  ///     itemBuilder: (context, index) => ListTile(title: Text(data[index])),
  ///   ),
  /// )
  /// ```
  final void Function(N notifier)? onInit;

  /// Function to determine if the widget should rebuild when state changes.
  ///
  /// If provided, this function is called with the previous and current state.
  /// Return `true` to rebuild, `false` to skip rebuilding.
  ///
  /// **Example:**
  /// ```dart
  /// NotifierBuilder<CounterNotifier, int>(
  ///   buildWhen: (previous, current) => current % 2 == 0, // Only rebuild for even numbers
  ///   builder: (context, count, child) => Text('Even count: $count'),
  /// )
  /// ```
  final ShouldProceedCallback<S>? buildWhen;

  /// Function to determine if the listener should be called when state changes.
  ///
  /// If provided, this function is called with the previous and current state.
  /// Return `true` to call the listener, `false` to skip it.
  ///
  /// **Example:**
  /// ```dart
  /// NotifierListener<CounterNotifier, int>(
  ///   listenWhen: (previous, current) => current > previous, // Only listen for increases
  ///   listener: (state) => print('Count increased to: $state'),
  ///   child: MyWidget(),
  /// )
  /// ```
  final ShouldProceedCallback<S>? listenWhen;

  /// Function to build the widget based on the current state and optional child.
  ///
  /// This function is called whenever the widget needs to rebuild. It receives
  /// the current state and an optional child widget.
  ///
  /// **Example:**
  /// ```dart
  /// NotifierBuilder<CounterNotifier, int>(
  ///   builder: (state, child) => Column(
  ///     children: [
  ///       Text('Count: $state'),
  ///       if (child != null) child, // Render the child if provided
  ///     ],
  ///   ),
  ///   child: ElevatedButton(
  ///     onPressed: () => context.read<CounterNotifier>().increment(),
  ///     child: Text('Increment'),
  ///   ),
  /// )
  /// ```
  final BuilderCallback<S>? builder;

  @override
  State<StatefulWidget> createState() =>
      BaseNotifierSingleChildBuilderState<N, S>();
}

/// State class for the base notifier single child builder.
///
/// This class manages the lifecycle and state of notifier-based widgets.
/// It handles:
/// - State caching and comparison
/// - Listener management
/// - Conditional rebuilding
/// - Widget initialization
///
/// **Key Features:**
/// - **Automatic State Caching**: Prevents unnecessary rebuilds by comparing states
/// - **Listener Management**: Automatically adds and removes listeners
/// - **Conditional Logic**: Supports `buildWhen` and `listenWhen` for fine-grained control
/// - **Initialization**: Calls `onInit` when the widget is first created
///
/// **Performance Notes:**
/// - Rebuilds are driven by the notifier, not by a provider dependency, so a
///   rejected `buildWhen` costs nothing beyond the predicate call
/// - Holds one state reference and one listener, and no cached subtree
class BaseNotifierSingleChildBuilderState<N extends BaseNotifier<S>,
    S extends Object?> extends SingleChildState<_BaseNotifierBuilder<N, S>> {
  /// The notifier currently provided above this widget.
  ///
  /// Re-read on every build so that replacing the provided instance, as
  /// `NotifierRegister.value` allows, rebinds the listener instead of leaving
  /// this widget attached to the old notifier for the rest of its life.
  late N _notifier = context.read<N>();

  /// The state as it was when the listener last ran.
  ///
  /// Advances on every notification, whether or not `listenWhen` accepted it,
  /// so `listenWhen` always receives the state immediately before the change
  /// it is being asked about.
  late S _listenerPrevious;

  /// The state this widget is currently showing.
  ///
  /// Advances only when `buildWhen` accepts a change, so the builder and
  /// `buildWhen` both see what is actually on screen rather than the latest
  /// notification.
  late S _state;

  @override
  void initState() {
    super.initState();
    _state = _notifier.state;
    _listenerPrevious = _state;
    _notifier.addListener(_onStateChanged);
    widget.onInit?.call(_notifier);
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  /// Builds with the state currently accepted for display.
  ///
  /// Selects the notifier by identity, so this widget depends on *which*
  /// notifier is provided without rebuilding every time that notifier
  /// notifies. Falls back to the child, then to an empty box, when no builder
  /// is given.
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final provided = context.select<N, N>(_identity);
    if (!identical(provided, _notifier)) _rebind(provided);

    return widget.builder?.call(_state, child) ??
        child ??
        const SizedBox.shrink();
  }

  /// Moves the listener from the previous notifier to [next].
  ///
  /// Called from `build`, so the state is assigned directly rather than
  /// through `setState`: this build is already the one that will show it.
  void _rebind(N next) {
    _notifier.removeListener(_onStateChanged);
    _notifier = next;
    _state = next.state;
    _listenerPrevious = _state;
    next.addListener(_onStateChanged);
  }

  /// Runs the listener and then the rebuild decision for one state change.
  ///
  /// The two predicates are independent: `listenWhen` compares against the
  /// previous notification, `buildWhen` against what is on screen.
  void _onStateChanged() {
    final next = _notifier.state;

    if (widget.listener != null) {
      final shouldCall =
          widget.listenWhen?.call(_listenerPrevious, next) ?? true;
      _listenerPrevious = next;
      if (shouldCall) widget.listener?.call(next);
    } else {
      _listenerPrevious = next;
    }

    if (widget.builder == null) return;

    final current = _notifier.state;
    if (!(widget.buildWhen?.call(_state, current) ?? true)) return;

    setState(() => _state = current);
  }

  /// Removes the listener from the notifier.
  ///
  /// This method is called during `dispose` to clean up the listener mechanism.
  /// It prevents memory leaks by removing the listener when the widget is disposed.
  void _removeListeners() {
    _notifier.removeListener(_onStateChanged);
  }
}
