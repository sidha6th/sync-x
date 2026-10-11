import 'package:flutter/widgets.dart';
import 'package:syncx/syncx.dart';

import 'counter_notifier.dart';

Widget hostNotifier(CounterNotifier notifier, Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: NotifierRegister<CounterNotifier>.value(
      notifier: notifier,
      child: child,
    ),
  );
}
