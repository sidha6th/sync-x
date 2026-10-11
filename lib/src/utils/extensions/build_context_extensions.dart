import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart' show Provider;
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;

/// Convenience access to the notifiers provided above a [BuildContext].
extension BuildContextExtensions on BuildContext {
  /// Returns the nearest notifier of type [N] without listening to it.
  ///
  /// Use this to call methods on a notifier, or to read its state once, from
  /// an event handler:
  ///
  /// ```dart
  /// onPressed: () => context.read<CounterNotifier>().increment(),
  /// ```
  ///
  /// This never rebuilds the widget when the state changes. To rebuild, use
  /// `NotifierBuilder` or one of the other SyncX widgets.
  ///
  /// Throws if no notifier of type [N] is registered above this context.
  N read<N extends BaseNotifier<Object?>>() =>
      Provider.of<N>(this, listen: false);
}
