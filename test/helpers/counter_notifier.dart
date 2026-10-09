import 'package:syncx/syncx.dart';

class CounterNotifier extends Notifier<int> {
  CounterNotifier([int initial = 0]) : super(initial);

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
