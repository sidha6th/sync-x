import 'package:flutter/widgets.dart' show VoidCallback;
import 'package:syncx/src/builders/sync/notifier_listener.dart';
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/models/async_state.dart';
import 'package:syncx/src/utils/models/base/base_async_state.dart';
import 'package:syncx/src/utils/models/error_state.dart';

/// A widget that listens for changes in the [AsyncState] of the provided [BaseNotifier] and triggers side effects.
///
/// [AsyncNotifierListener] is a convenience widget for listening to an asynchronous [BaseNotifier]
/// and performing side effects via listeners when the state changes, without rebuilding the UI.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of data managed by the notifier.
class AsyncNotifierListener<N extends BaseNotifier<BaseAsyncState<S>>,
    S extends Object?> extends NotifierListener<N, BaseAsyncState<S>> {
  /// Creates an [AsyncNotifierListener].
  ///
  /// [dataListener], [loadingListener], and [errorListener] are optional callbacks invoked for side effects
  /// when the state is [AsyncState.data], [AsyncState.loading], or [AsyncState.error], respectively.
  ///
  /// [listenWhen] is an optional predicate that determines whether to call listeners when the data changes.
  ///
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
  ///
  /// Example (incorrect usage):
  /// ```dart
  /// AsyncNotifierListener<MyAsyncNotifier, String>(
  ///   // Do NOT do this:
  ///   onInit: (notifier) => notifier.onInit(),
  ///   dataListener: (data) => print(data),
  ///   loadingListener: () => print('Loading...'),
  ///   errorListener: (error) => print('Error: \\${error.message}'),
  ///   child: MyWidget(),
  /// )
  /// ```
  ///
  /// [child] is the widget below this widget in the tree.
  /// [key] is the widget key.
  AsyncNotifierListener({
    required super.child,
    this.dataListener,
    this.errorListener,
    this.loadingListener,
    bool Function(S? previous, S? current)? listenWhen,
    super.notifier,
    super.onInit,
    super.key,
  }) : super(
          listener: (state) => state.when(
            error: (e) => errorListener?.call(e),
            loading: () => loadingListener?.call(),
            data: (data) => dataListener?.call(data),
          ),
          listenWhen: (previous, current) =>
              listenWhen?.call(previous.data, current.data) ?? true,
        );

  /// Optional callback for side effects when the state is [AsyncState.data].
  final void Function(S data)? dataListener;

  /// Optional callback for side effects when the state is [AsyncState.loading].
  final VoidCallback? loadingListener;

  /// Optional callback for side effects when the state is [AsyncState.error].
  final void Function(ErrorState error)? errorListener;
}
