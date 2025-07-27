import 'package:flutter/material.dart' show Widget;
import 'package:syncx/src/builders/sync/notifier_builder.dart';
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;
import 'package:syncx/src/utils/models/async_state.dart';
import 'package:syncx/src/utils/models/base/base_async_state.dart';
import 'package:syncx/src/utils/models/error_state.dart';

/// A widget that rebuilds when the [AsyncState] of the provided [BaseNotifier] changes.
///
/// [AsyncNotifierBuilder] is a convenience widget for listening to an asynchronous [BaseNotifier]
/// and rebuilding its child whenever the state changes, optionally using [buildWhen] to control rebuilds.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of data managed by the notifier.
class AsyncNotifierBuilder<N extends BaseNotifier<BaseAsyncState<S>>,
    S extends Object?> extends NotifierBuilder<N, BaseAsyncState<S>> {
  /// Creates an [AsyncNotifierBuilder].
  ///
  /// [dataBuilder] is called to build the widget tree when the state is [AsyncState.data].
  /// [loadingBuilder] is called when the state is [AsyncState.loading].
  /// [errorBuilder] is called when the state is [AsyncState.error].
  ///
  /// [buildWhen] is an optional predicate that determines whether to rebuild when the data changes.
  ///
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
  ///
  /// Example (incorrect usage):
  /// ```dart
  /// AsyncNotifierBuilder<MyAsyncNotifier, String>(
  ///   // Do NOT do this:
  ///   onInit: (notifier) => notifier.onInit(),
  ///   dataBuilder: (data) => Text(data),
  ///   loadingBuilder: () => CircularProgressIndicator(),
  ///   errorBuilder: (error) => Text('Error: \\${error.message}'),
  /// )
  /// ```
  ///
  /// [key] is the widget key.
  AsyncNotifierBuilder({
    required this.dataBuilder,
    required this.errorBuilder,
    required this.loadingBuilder,
    final bool Function(S? previous, S? current)? buildWhen,
    super.notifier,
    super.onInit,
    super.key,
  }) : super(
          builder: (context, state) => state.when(
            data: dataBuilder,
            error: errorBuilder,
            loading: loadingBuilder,
          ),
          buildWhen: (previous, current) =>
              buildWhen?.call(previous.data, current.data) ?? true,
        );

  /// Called when the state is [AsyncState.loading].
  final Widget Function() loadingBuilder;

  /// Called when the state is [AsyncState.data].
  final Widget Function(S state) dataBuilder;

  /// Called when the state is [AsyncState.error].
  final Widget Function(ErrorState error) errorBuilder;
}
