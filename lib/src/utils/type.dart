import 'package:flutter/widgets.dart' show Widget;

typedef ShouldProceedCallback<S> = bool Function(
  S previous,
  S current,
);

typedef BuilderCallback<S> = Widget Function(
  S state,
  Widget? child,
);
