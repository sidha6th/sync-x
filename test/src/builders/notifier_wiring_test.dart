import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../helpers/counter_notifier.dart';

class SecondNotifier extends Notifier<int> {
  SecondNotifier() : super(0);

  void increment() => setState(state + 1);
}

Widget wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('create constructor resolves lazily', (tester) async {
    await tester.pumpWidget(
      wrap(
        NotifierRegister<CounterNotifier>(
          create: (_) => CounterNotifier(),
          child: NotifierBuilder<CounterNotifier, int>(
            builder: (state, child) => Text('$state'),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('swapping the provided notifier instance', (tester) async {
    final first = CounterNotifier(1);
    final second = CounterNotifier(99);

    Widget host(CounterNotifier n) => wrap(
          NotifierRegister<CounterNotifier>.value(
            notifier: n,
            child: NotifierBuilder<CounterNotifier, int>(
              builder: (state, child) => Text('$state'),
            ),
          ),
        );

    await tester.pumpWidget(host(first));
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(host(second));
    await tester.pump();
    expect(find.text('99'), findsOneWidget);

    second.increment();
    await tester.pump();
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('two notifier types rebuild independently', (tester) async {
    final a = CounterNotifier();
    final b = SecondNotifier();
    var aBuilds = 0;
    var bBuilds = 0;

    await tester.pumpWidget(
      wrap(
        NotifierRegister<CounterNotifier>.value(
          notifier: a,
          child: NotifierRegister<SecondNotifier>.value(
            notifier: b,
            child: Column(
              children: <Widget>[
                NotifierBuilder<CounterNotifier, int>(
                  builder: (state, child) {
                    aBuilds++;
                    return Text('a$state');
                  },
                ),
                NotifierBuilder<SecondNotifier, int>(
                  builder: (state, child) {
                    bBuilds++;
                    return Text('b$state');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    a.increment();
    await tester.pump();

    expect(aBuilds, 2);
    expect(bBuilds, 1);
  });

  testWidgets('consumer runs the listener before the rebuild', (tester) async {
    final notifier = CounterNotifier();
    final order = <String>[];

    await tester.pumpWidget(
      wrap(
        NotifierRegister<CounterNotifier>.value(
          notifier: notifier,
          child: NotifierConsumer<CounterNotifier, int>(
            listener: (_) => order.add('listen'),
            builder: (state, child) {
              order.add('build$state');
              return Text('$state');
            },
          ),
        ),
      ),
    );

    notifier.increment();
    await tester.pump();

    expect(order, <String>['build0', 'listen', 'build1']);
  });

  testWidgets('a listener that sets state again settles', (tester) async {
    final notifier = CounterNotifier();

    await tester.pumpWidget(
      wrap(
        NotifierRegister<CounterNotifier>.value(
          notifier: notifier,
          child: NotifierConsumer<CounterNotifier, int>(
            listener: (state) {
              if (state == 1) notifier.set(50);
            },
            builder: (state, child) => Text('$state'),
          ),
        ),
      ),
    );

    notifier.increment();
    await tester.pump();

    expect(find.text('50'), findsOneWidget);
  });
}
