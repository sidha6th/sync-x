import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart' show Provider;
import 'package:syncx/src/notifier/base/base_notifier.dart' show BaseNotifier;

extension BuildContextExtensions on BuildContext {
  N read<N extends BaseNotifier>() => Provider.of<N>(this, listen: false);
}
