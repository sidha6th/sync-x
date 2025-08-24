// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'
    show BuildContext, SizedBox, State, StatefulWidget, Widget;
import 'package:provider/provider.dart' show Provider;
import 'package:provider/single_child_widget.dart'
    show SingleChildStatefulWidget, SingleChildState;
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/extensions/build_context_extensions.dart';
import 'package:syncx/src/utils/type.dart';

part '../sync/notifier_builder.dart';
part '../sync/notifier_consumer.dart';
part '../sync/notifier_listener.dart';

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
/// **Performance Optimizations:**
/// - Caches the built widget to avoid unnecessary rebuilds
/// - Only rebuilds when state actually changes
/// - Efficient listener management
class BaseNotifierSingleChildBuilderState<N extends BaseNotifier<S>,
    S extends Object?> extends SingleChildState<_BaseNotifierBuilder<N, S>> {
  /// The notifier instance obtained from the widget tree.
  ///
  /// This is initialized once and reused throughout the widget's lifecycle.
  late final _notifier = context.read<N>();

  /// The previous state value for comparison.
  ///
  /// Used to determine if a rebuild is necessary by comparing with the current state.
  late S _previous = _notifier.state;

  /// Cached widget to avoid unnecessary rebuilds.
  ///
  /// This is updated only when the state actually changes and `buildWhen` returns true.
  Widget? _cachedWidget;

  @override
  void initState() {
    super.initState();
    _addListeners();
    widget.onInit?.call(_notifier);
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  /// Builds the widget with the current state and optional child.
  ///
  /// This method:
  /// 1. Gets the current state from the notifier
  /// 2. Compares it with the previous state
  /// 3. Rebuilds only if necessary (based on `buildWhen` logic)
  /// 4. Returns the cached widget or builds a new one
  ///
  /// **Performance Notes:**
  /// - Uses caching to avoid unnecessary rebuilds
  /// - Only calls the builder function when state actually changes
  /// - Falls back to child or empty widget if no builder is provided
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final state =
        _shouldWatch ? Provider.of<N>(context).state : _notifier.state;
    if (_shouldWatch && _shouldRebuild) {
      _previous = state;
      _cachedWidget = widget.builder?.call(state, child);
      return _cachedWidget!;
    }

    return _cachedWidget ??= (widget.builder?.call(state, child) ??
        child ??
        const SizedBox.shrink());
  }

  /// Triggers the listener function when state changes.
  ///
  /// This method is called by the notifier's listener mechanism when the state changes.
  /// It checks if the listener should be called based on `listenWhen` logic.
  void _triggerListener() {
    if (_shouldListen) widget.listener?.call(_notifier.state);
  }

  /// Determines if the listener should be called for the given state change.
  ///
  /// **Logic:**
  /// 1. Returns `false` if the state hasn't changed
  /// 2. If `listenWhen` is provided, uses its logic
  /// 3. Otherwise, returns `true` (always listen)
  ///
  /// **Parameters:**
  /// - `newState`: The current state value
  ///
  /// **Returns:** `true` if the listener should be called, `false` otherwise
  bool get _shouldListen {
    return (widget.listenWhen?.call(_previous, _notifier.state) ?? true);
  }

  /// Determines if the widget should rebuild for the given state change.
  ///
  /// **Logic:**
  /// 1. Returns `false` if no builder is provided
  /// 2. Returns `false` if the state hasn't changed
  /// 3. If `buildWhen` is provided, uses its logic
  /// 4. Otherwise, returns `true` (always rebuild)
  ///
  /// **Parameters:**
  /// - `newState`: The current state value
  ///
  /// **Returns:** `true` if the widget should rebuild, `false` otherwise
  bool get _shouldRebuild {
    return (widget.buildWhen?.call(_previous, _notifier.state) ?? true);
  }

  /// Determines if the widget should watch the notifier.
  ///
  /// **Returns:** `true` if the widget should watch the notifier, `false` otherwise
  bool get _shouldWatch => widget.builder != null;

  /// Adds the listener to the notifier if a listener function is provided.
  ///
  /// This method is called during `initState` to set up the listener mechanism.
  /// It only adds the listener if `widget.listener` is not null.
  void _addListeners() {
    if (widget.listener == null) return;
    _notifier.addListener(_triggerListener);
  }

  /// Removes the listener from the notifier.
  ///
  /// This method is called during `dispose` to clean up the listener mechanism.
  /// It prevents memory leaks by removing the listener when the widget is disposed.
  void _removeListeners() {
    _notifier.removeListener(_triggerListener);
  }
}
