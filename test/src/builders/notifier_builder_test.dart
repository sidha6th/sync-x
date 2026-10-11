import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../helpers/counter_notifier.dart';
import '../../helpers/pump.dart';

void main() {
  group('NotifierBuilder', () {
    testWidgets('a new child is rendered when the state has not changed',
        (tester) async {
      final notifier = CounterNotifier();

      Widget host(String label) {
        return hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            builder: (state, child) => child!,
            child: Text(label),
          ),
        );
      }

      await tester.pumpWidget(host('a'));
      expect(find.text('a'), findsOneWidget);

      await tester.pumpWidget(host('b'));

      expect(find.text('b'), findsOneWidget);
      expect(find.text('a'), findsNothing);
    });

    testWidgets('a new child is rendered while buildWhen suppresses rebuilds',
        (tester) async {
      final notifier = CounterNotifier();

      Widget host(String label) {
        return hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            buildWhen: (previous, current) => false,
            builder: (state, child) => child!,
            child: Text(label),
          ),
        );
      }

      await tester.pumpWidget(host('a'));
      expect(find.text('a'), findsOneWidget);

      await tester.pumpWidget(host('b'));

      expect(find.text('b'), findsOneWidget);
      expect(find.text('a'), findsNothing);
    });

    testWidgets('a builder-less listener renders a new child', (tester) async {
      final notifier = CounterNotifier();

      Widget host(String label) {
        return hostNotifier(
          notifier,
          NotifierListener<CounterNotifier, int>(
            listener: (_) {},
            child: Text(label),
          ),
        );
      }

      await tester.pumpWidget(host('a'));
      expect(find.text('a'), findsOneWidget);

      await tester.pumpWidget(host('b'));

      expect(find.text('b'), findsOneWidget);
      expect(find.text('a'), findsNothing);
    });

    testWidgets('a new builder closure is used on rebuild', (tester) async {
      final notifier = CounterNotifier();

      Widget host(String prefix) {
        return hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            builder: (state, child) => Text('$prefix$state'),
          ),
        );
      }

      await tester.pumpWidget(host('a'));
      expect(find.text('a0'), findsOneWidget);

      await tester.pumpWidget(host('b'));

      expect(find.text('b0'), findsOneWidget);
    });

    testWidgets('builds once on mount and once per accepted change',
        (tester) async {
      final notifier = CounterNotifier();
      var builds = 0;

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            builder: (state, child) {
              builds++;
              return Text('$state');
            },
          ),
        ),
      );
      expect(builds, 1);

      notifier.increment();
      await tester.pump();

      expect(builds, 2);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('an unchanged state does not rebuild', (tester) async {
      final notifier = CounterNotifier();
      var builds = 0;

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            builder: (state, child) {
              builds++;
              return Text('$state');
            },
          ),
        ),
      );

      notifier.set(0);
      await tester.pump();

      expect(builds, 1);
    });

    testWidgets('buildWhen false suppresses the rebuild', (tester) async {
      final notifier = CounterNotifier();
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
      expect(builds, 1);

      notifier.increment();
      await tester.pump();
      expect(builds, 1);
      expect(find.text('0'), findsOneWidget);

      notifier.increment();
      await tester.pump();
      expect(builds, 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('buildWhen compares against the state on screen',
        (tester) async {
      final notifier = CounterNotifier();
      final pairs = <List<int>>[];

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            buildWhen: (previous, current) {
              pairs.add(<int>[previous, current]);
              return current - previous > 1;
            },
            builder: (state, child) => Text('$state'),
          ),
        ),
      );

      notifier.increment();
      await tester.pump();
      notifier.increment();
      await tester.pump();

      expect(pairs, <List<int>>[
        <int>[0, 1],
        <int>[0, 2],
      ]);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('onInit runs once with the notifier', (tester) async {
      final notifier = CounterNotifier();
      final seen = <CounterNotifier>[];

      await tester.pumpWidget(
        hostNotifier(
          notifier,
          NotifierBuilder<CounterNotifier, int>(
            onInit: seen.add,
            builder: (state, child) => Text('$state'),
          ),
        ),
      );

      notifier.increment();
      await tester.pump();

      expect(seen, <CounterNotifier>[notifier]);
    });
  });
}
