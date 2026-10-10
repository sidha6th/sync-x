import 'package:syncx/syncx.dart';

class CounterNotifier extends Notifier<int> {
  CounterNotifier([super.initial = 0]);

  int initCount = 0;
  final List<int> updates = <int>[];

  int get current => state;

  @override
  void onInit() => initCount++;

  @override
  void onUpdate(int state) => updates.add(state);

  void increment() => setState(state + 1);

  void set(
    int next, {
    bool notify = true,
    bool forced = false,
    bool Function(int curr, int next)? equalityCheck,
  }) {
    setState(
      next,
      notify: notify,
      forced: forced,
      equalityCheck: equalityCheck,
    );
  }
}

class PlainNotifier extends Notifier<int> {
  PlainNotifier() : super(0);

  int get current => state;

  void increment() => setState(state + 1);
}
