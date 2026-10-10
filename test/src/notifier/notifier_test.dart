// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/counter_notifier.dart';
import '../../helpers/listener_spy.dart';

void main() {
  group('Notifier', () {
    test('starts at the initial state', () {
      expect(CounterNotifier(7).state, 7);
    });

    test('onInit runs exactly once per instance', () {
      expect(CounterNotifier().initCount, 1);
    });

    test('setState updates the state and notifies once', () {
      final notifier = CounterNotifier();
      final spy = ListenerSpy();
      notifier.addListener(spy.call);

      notifier.increment();

      expect(notifier.state, 1);
      expect(spy.calls, 1);
      expect(notifier.updates, <int>[1]);
    });

    test('an unchanged state does not notify and does not call onUpdate', () {
      final notifier = CounterNotifier();
      final spy = ListenerSpy();
      notifier.addListener(spy.call);

      notifier.set(0);

      expect(spy.calls, 0);
      expect(notifier.updates, isEmpty);
    });

    test('forced notifies even when the state is unchanged', () {
      final notifier = CounterNotifier();
      final spy = ListenerSpy();
      notifier.addListener(spy.call);

      notifier.set(0, forced: true);

      expect(spy.calls, 1);
      expect(notifier.updates, <int>[0]);
    });

    test('notify false writes the state and calls onUpdate without notifying',
        () {
      final notifier = CounterNotifier();
      final spy = ListenerSpy();
      notifier.addListener(spy.call);

      notifier.set(5, notify: false);

      expect(notifier.state, 5);
      expect(notifier.updates, <int>[5]);
      expect(spy.calls, 0);
    });

    test('a custom equalityCheck suppresses the update when it reports equal',
        () {
      final notifier = CounterNotifier(3);
      final spy = ListenerSpy();
      notifier.addListener(spy.call);

      notifier.set(-3, equalityCheck: (curr, next) => curr.abs() == next.abs());

      expect(notifier.state, 3);
      expect(spy.calls, 0);
    });

    test('a removed listener is not called', () {
      final notifier = CounterNotifier();
      final spy = ListenerSpy();
      notifier.addListener(spy.call);
      notifier.removeListener(spy.call);

      notifier.increment();

      expect(spy.calls, 0);
    });

    test('notifyListeners throws UnsupportedError', () {
      // ignore: invalid_use_of_protected_member
      expect(CounterNotifier().notifyListeners, throwsUnsupportedError);
    });

    test('the default onUpdate hook accepts a change', () {
      final notifier = PlainNotifier();

      notifier.increment();

      expect(notifier.state, 1);
    });

    test('toString includes the current state', () {
      expect(CounterNotifier(4).toString(), contains('4'));
    });
  });
}
