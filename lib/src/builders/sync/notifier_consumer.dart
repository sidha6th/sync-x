part of '../base/base_notifier_builder.dart';

/// A widget that both rebuilds and listens to state changes from a [BaseNotifier].
///
/// [NotifierConsumer] allows you to rebuild the widget tree and perform side effects
/// in response to state changes, using [buildWhen] and [listenWhen] to control behavior.
///
/// [N] is the type of [BaseNotifier] and [S] is the type of state managed by the notifier.
class NotifierConsumer<N extends BaseNotifier<S>, S extends Object?>
    extends _BaseNotifierBuilder<N, S> {
  /// Creates a [NotifierConsumer].
  ///
  /// [builder] is called to build the widget tree based on the current state.
  ///
  /// [listener] is called for side effects when the state changes.
  ///
  /// [buildWhen] is an optional predicate that determines whether to rebuild when the state changes.
  ///
  /// [listenWhen] is an optional predicate that determines whether to call [listener] when the state changes.
  ///
  /// [onInit] is an optional callback invoked with the notifier when the widget is initialized.
  ///
  /// Note: Do not manually call the notifier's `onInit()` method here. The notifier itself will automatically
  /// trigger its own `onInit()` when it is created, so calling it again would result in duplicate invocations.
  ///
  /// Example (incorrect usage):
  /// ```dart
  /// NotifierConsumer<Notifier, State>(
  ///   // Do NOT do this:
  ///   onInit: (notifier) => notifier.onInit(),
  ///   builder: (context, state) => Text('State: $state'),
  /// )
  /// ```
  ///
  /// [key] is the widget key.
  const NotifierConsumer({
    required BuilderCallback<S> super.builder,
    required super.listener,
    super.listenWhen,
    super.buildWhen,
    super.child,
    super.onInit,
    super.key,
  });
}
