import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../helpers/counter_notifier.dart';

void main() {
  group('NotifierRegister', () {
    testWidgets('a widget onInit may set state synchronously', (tester) async {
      await tester.pumpWidget(
        NotifierRegister<CounterNotifier>(
          create: (_) => CounterNotifier(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: NotifierBuilder<CounterNotifier, int>(
              onInit: (notifier) => notifier.increment(),
              builder: (count, child) => Text('$count'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('a widget onInit may set state synchronously under .value',
        (tester) async {
      final notifier = CounterNotifier();
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        NotifierRegister<CounterNotifier>.value(
          notifier: notifier,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: NotifierBuilder<CounterNotifier, int>(
              onInit: (n) => n.increment(),
              builder: (count, child) => Text('$count'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('create disposes the notifier it owns', (tester) async {
      late CounterNotifier created;

      await tester.pumpWidget(
        NotifierRegister<CounterNotifier>(
          create: (_) {
            return created = CounterNotifier();
          },
          lazy: false,
          child: const SizedBox.shrink(),
        ),
      );

      expect(created.isDisposed, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(created.isDisposed, isTrue);
    });

    testWidgets('.value does not dispose a notifier it does not own',
        (tester) async {
      final notifier = CounterNotifier();
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        NotifierRegister<CounterNotifier>.value(
          notifier: notifier,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(notifier.isDisposed, isFalse);
    });

    testWidgets('builder receives a context that can read the notifier',
        (tester) async {
      await tester.pumpWidget(
        NotifierRegister<CounterNotifier>(
          create: (_) => CounterNotifier(3),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${context.read<CounterNotifier>().state}'),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });
  });
}
