import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../helpers/counter_notifier.dart';
import '../../helpers/pump.dart';

void main() {
  group('rebuild parity with ValueListenableBuilder', () {
    testWidgets('the same sequence costs the same number of builds',
        (tester) async {
      const steps = 5;

      final value = ValueNotifier<int>(0);
      addTearDown(value.dispose);
      var valueBuilds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<int>(
            valueListenable: value,
            builder: (_, state, __) {
              valueBuilds++;
              return Text('$state');
            },
          ),
        ),
      );
      for (var i = 0; i < steps; i++) {
        value.value = value.value + 1;
        await tester.pump();
      }

      final notifier = CounterNotifier();
      addTearDown(notifier.dispose);
      var notifierBuilds = 0;

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            builder: (state, child) {
              notifierBuilds++;
              return Text('$state');
            },
          ),
        ),
      );
      for (var i = 0; i < steps; i++) {
        notifier.increment();
        await tester.pump();
      }

      expect(notifierBuilds, valueBuilds);
      expect(notifierBuilds, steps + 1);
    });

    testWidgets('a rejected buildWhen costs no build at all', (tester) async {
      final notifier = CounterNotifier();
      addTearDown(notifier.dispose);
      var builds = 0;

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            buildWhen: (previous, current) => current.isEven,
            builder: (state, child) {
              builds++;
              return Text('$state');
            },
          ),
        ),
      );

      for (var i = 0; i < 4; i++) {
        notifier.increment();
        await tester.pump();
      }

      expect(builds, 3);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a notifier with no builder never rebuilds', (tester) async {
      final notifier = CounterNotifier();
      addTearDown(notifier.dispose);
      var childBuilds = 0;

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierListener<CounterNotifier, int>(
            listener: (_) {},
            child: Builder(
              builder: (_) {
                childBuilds++;
                return const Text('static');
              },
            ),
          ),
        ),
      );

      for (var i = 0; i < 4; i++) {
        notifier.increment();
        await tester.pump();
      }

      expect(childBuilds, 1);
    });
  });
}
