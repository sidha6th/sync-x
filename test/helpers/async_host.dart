import 'package:flutter/widgets.dart';
import 'package:syncx/syncx.dart';

import 'test_async_notifier.dart';

Widget hostAsync(ControllableAsyncNotifier notifier, Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: NotifierRegister<ControllableAsyncNotifier>.value(
      notifier: notifier,
      child: child,
    ),
  );
}
