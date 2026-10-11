import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../helpers/counter_notifier.dart';
import '../../helpers/pump.dart';

void main() {
  group('NotifierListener', () {
    testWidgets('listenWhen advances previous across consecutive changes',
        (tester) async {
      final notifier = CounterNotifier();
      final pairs = <List<int>>[];

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierListener<CounterNotifier, int>(
            listenWhen: (previous, current) {
              pairs.add(<int>[previous, current]);
              return true;
            },
            listener: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.increment();
      notifier.increment();
      notifier.increment();
      await tester.pump();

      expect(pairs, <List<int>>[
        <int>[0, 1],
        <int>[1, 2],
        <int>[2, 3],
      ]);
    });

    testWidgets('listener fires for every accepted change', (tester) async {
      final notifier = CounterNotifier();
      final seen = <int>[];

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierListener<CounterNotifier, int>(
            listener: seen.add,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.increment();
      notifier.increment();
      await tester.pump();

      expect(seen, <int>[1, 2]);
    });

    testWidgets('listenWhen false suppresses the listener but still advances',
        (tester) async {
      final notifier = CounterNotifier();
      final seen = <int>[];

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierListener<CounterNotifier, int>(
            listenWhen: (previous, current) => current - previous > 1,
            listener: seen.add,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.increment();
      notifier.set(5);
      notifier.increment();
      await tester.pump();

      expect(seen, <int>[5]);
    });

    testWidgets('a disposed listener is detached', (tester) async {
      final notifier = CounterNotifier();
      final seen = <int>[];

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierListener<CounterNotifier, int>(
            listener: seen.add,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(
        hostNotifier(notifier, const SizedBox.shrink()),
      );

      notifier.increment();
      await tester.pump();

      expect(seen, isEmpty);
    });
  });
}
