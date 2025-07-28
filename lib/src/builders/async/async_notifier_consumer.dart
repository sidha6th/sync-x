import 'package:flutter/widgets.dart' show VoidCallback, Widget;
import 'package:syncx/src/builders/sync/notifier_consumer.dart';
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/models/async_state.dart';
import 'package:syncx/src/utils/models/base/base_async_state.dart';
import 'package:syncx/src/utils/models/error_state.dart';

/// A widget that rebuilds and listens when the [AsyncState] of the provided [BaseNotifier] changes.
///
/// [AsyncNotifierConsumer] is a convenience widget for listening to an asynchronous [BaseNotifier],
/// rebuilding its child whenever the state changes, and performing side effects via listeners.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of data managed by the notifier.
class AsyncNotifierConsumer<N extends BaseNotifier<BaseAsyncState<S>>,
    S extends Object?> extends NotifierConsumer<N, BaseAsyncState<S>> {
  /// Creates an [AsyncNotifierConsumer].
  const AsyncNotifierConsumer({
    required super.builder,
    required super.listener,
    super.buildWhen,
    super.listenWhen,
    super.notifier,
    super.onInit,
    super.key,
  });

  ///
  /// [dataBuilder] is called to build the widget tree when the state is [AsyncState.data].
  /// [loadingBuilder] is called when the state is [AsyncState.loading].
  /// [errorBuilder] is called when the state is [AsyncState.error].
  ///
  /// [dataListener], [loadingListener], and [errorListener] are optional callbacks invoked for side effects
  /// when the state is [AsyncState.data], [AsyncState.loading], or [AsyncState.error], respectively.
  ///
  /// [buildWhen] is an optional predicate that determines whether to rebuild when the data changes.
  /// [listenWhen] is an optional predicate that determines whether to call listeners when the data changes.
  ///
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
  ///
  /// Example (incorrect usage):
  /// ```dart
  /// AsyncNotifierConsumer<MyAsyncNotifier, String>(
  ///   // Do NOT do this:
  ///   onInit: (notifier) => notifier.onInit(),
  ///   dataBuilder: (data) => Text(data),
  ///   loadingBuilder: () => CircularProgressIndicator(),
  ///   errorBuilder: (error) => Text('Error: \\${error.message}'),
  /// )
  /// ```
  ///
  /// [key] is the widget key.
  AsyncNotifierConsumer.withData({
    /// Called when the state is [AsyncState.loading].
    required final Widget Function() loadingBuilder,

    /// Called when the state is [AsyncState.data].
    required final Widget Function(S state) dataBuilder,

    /// Called when the state is [AsyncState.error].
    required final Widget Function(ErrorState error) errorBuilder,

    /// Optional callback for side effects when the state is [AsyncState.data].
    final void Function(S data)? dataListener,

    /// Optional callback for side effects when the state is [AsyncState.loading].
    final VoidCallback? loadingListener,

    /// Optional callback for side effects when the state is [AsyncState.error].
    final void Function(ErrorState error)? errorListener,
    bool Function(S? previous, S? current)? buildWhen,
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
          builder: (context, state) => state.when(
            data: dataBuilder,
            error: errorBuilder,
            loading: loadingBuilder,
          ),
          buildWhen: (previous, current) =>
              buildWhen?.call(previous.data, current.data) ?? true,
          listenWhen: (previous, current) =>
              listenWhen?.call(previous.data, current.data) ?? true,
        );
}
