import 'package:flutter/widgets.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:syncx/src/notifier/base/base_notifier.dart';

/// A widget that registers a [BaseNotifier] in the widget tree using [ChangeNotifierProvider].
///
/// [NotifierRegister] is a convenience widget for providing a notifier to its descendants.
///
/// [N] is the type of [BaseNotifier].
class NotifierRegister<N extends BaseNotifier<Object?>>
    extends StatelessWidget {
  /// Creates a [NotifierRegister].
  ///
  /// [create] is a function that returns a new notifier instance.
  /// [lazy] determines whether the notifier should be created lazily.
  /// [child] is an optional static child widget.
  /// [builder] is an optional builder function for customizing the widget tree.
  /// [key] is the widget key.
  const NotifierRegister({
    required this.create,
    this.lazy,
    this.child,
    this.builder,
    super.key,
  });

  /// Whether the notifier should be created lazily.
  final bool? lazy;

  /// An optional static child widget.
  final Widget? child;

  /// A function that creates a new notifier instance.
  final N Function(BuildContext context) create;

  /// An optional builder function for customizing the widget tree.
  final Widget Function(BuildContext context, Widget? child)? builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: key,
      lazy: lazy,
      create: create,
      builder: builder,
      child: child,
    );
  }
}
