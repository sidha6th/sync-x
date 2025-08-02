import 'package:syncx/syncx.dart';

class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  void increment() => setState(state + 1);
  void decrement() => setState(state - 1);
}
