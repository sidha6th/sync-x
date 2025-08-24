import 'package:flutter/widgets.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:syncx/src/notifier/base/base_notifier.dart';

/// A widget that registers a [BaseNotifier] in the widget tree using [ChangeNotifierProvider].
///
/// [NotifierRegister] is a convenience widget for providing a notifier to its descendants,
/// making it accessible throughout the widget subtree. It acts as a wrapper around
/// Flutter's [ChangeNotifierProvider] with SyncX-specific optimizations.
///
/// [N] is the type of [BaseNotifier].
///
/// This widget supports two creation patterns:
/// - Creating a new notifier instance with [NotifierRegister]
/// - Providing an existing notifier instance with [NotifierRegister.value]
///
/// Example usage:
/// ```dart
/// // Create a new notifier instance
/// NotifierRegister<CounterNotifier>(
///   create: (context) => CounterNotifier(),
///   child: MyApp(),
/// )
///
/// // Provide an existing notifier instance
/// NotifierRegister<CounterNotifier>.value(
///   notifier: existingCounterNotifier,
///   child: MyApp(),
/// )
/// ```
class NotifierRegister<N extends BaseNotifier<Object?>>
    extends StatelessWidget {
  /// Creates a [NotifierRegister] that creates a new notifier instance.
  ///
  /// [create] is a function that returns a new notifier instance when called.
  /// [lazy] determines whether the notifier should be created lazily (default: true).
  /// [child] is an optional static child widget.
  /// [builder] is an optional builder function for customizing the widget tree.
  /// [key] is the widget key.
  ///
  /// Use this constructor when you want to create a new notifier instance that
  /// will be automatically disposed when the widget is removed from the tree.
  ///
  /// Example:
  /// ```dart
  /// NotifierRegister<CounterNotifier>(
  ///   create: (context) => CounterNotifier(),
  ///   lazy: false, // Create immediately
  ///   child: MyApp(),
  /// )
  /// ```
  const NotifierRegister({
    required this.create,
    this.lazy,
    this.child,
    this.builder,
    super.key,
  }) : notifier = null;

  /// Creates a [NotifierRegister.value] that provides an existing notifier instance.
  ///
  /// [notifier] is the existing notifier instance to provide.
  /// [child] is an optional static child widget.
  /// [builder] is an optional builder function for customizing the widget tree.
  /// [key] is the widget key.
  ///
  /// Use this constructor when you want to provide an existing notifier instance,
  /// typically for sharing a notifier across multiple parts of your app or
  /// when the notifier lifecycle is managed elsewhere.
  ///
  /// **Note:** The notifier will NOT be automatically disposed when using this constructor.
  /// You are responsible for managing its lifecycle.
  ///
  /// Example:
  /// ```dart
  /// final counterNotifier = CounterNotifier();
  ///
  /// NotifierRegister<CounterNotifier>.value(
  ///   notifier: counterNotifier,
  ///   child: MyApp(),
  /// )
  /// ```
  const NotifierRegister.value({
    required N this.notifier,
    this.child,
    this.builder,
    super.key,
  })  : create = null,
        lazy = null;

  /// Whether the notifier should be created lazily.
  ///
  /// When true (default), the notifier is created only when first accessed.
  /// When false, the notifier is created immediately when the widget is built.
  ///
  /// This parameter is ignored when using [NotifierRegister.value].
  final bool? lazy;

  /// An optional static child widget.
  ///
  /// This widget is passed to the [builder] function if provided,
  /// or used directly if no [builder] is specified.
  final Widget? child;

  /// A function that creates a new notifier instance.
  ///
  /// This function is called when a new notifier needs to be created.
  /// It receives the [BuildContext] and should return a new notifier instance.
  ///
  /// Only used with the default constructor. Set to null when using [NotifierRegister.value].
  final N Function(BuildContext context)? create;

  /// An optional builder function for customizing the widget tree.
  ///
  /// If provided, this function is called with the [BuildContext] and [child] widget,
  /// allowing you to wrap the child with additional widgets.
  ///
  /// Example:
  /// ```dart
  /// NotifierRegister<CounterNotifier>(
  ///   create: (context) => CounterNotifier(),
  ///   builder: (context, child) => Material(child: child),
  ///   child: MyApp(),
  /// )
  /// ```
  final Widget Function(BuildContext context, Widget? child)? builder;

  /// The existing notifier instance to provide.
  ///
  /// Only used with [NotifierRegister.value]. Set to null when using the default constructor.
  final N? notifier;

  @override
  Widget build(BuildContext context) {
    if (create == null) {
      return ChangeNotifierProvider.value(
        key: key,
        value: notifier!,
        builder: builder,
        child: child,
      );
    }

    return ChangeNotifierProvider(
      key: key,
      lazy: lazy,
      create: create!,
      builder: builder,
      child: child,
    );
  }
}
