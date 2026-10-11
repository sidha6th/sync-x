import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../../helpers/async_host.dart';
import '../../../helpers/test_async_notifier.dart';

void main() {
  group('AsyncNotifierConsumer', () {
    testWidgets('builds and listens on the raw state', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final seen = <String?>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierConsumer<ControllableAsyncNotifier, String>(
            listener: (state) => seen.add(state.data),
            builder: (state, child) => Text(state.data ?? 'none'),
          ),
        ),
      );

      notifier.toData('next');
      await tester.pump();

      expect(seen, <String?>['next']);
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('buildWhen and listenWhen are independent', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final seen = <String?>[];
      var builds = 0;

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierConsumer<ControllableAsyncNotifier, String>(
            buildWhen: (previous, current) => current.data == 'build',
            listenWhen: (previous, current) => current.data == 'listen',
            listener: (state) => seen.add(state.data),
            builder: (state, child) {
              builds++;
              return Text(state.data ?? 'none');
            },
          ),
        ),
      );

      notifier.toData('listen');
      await tester.pump();
      expect(seen, <String?>['listen']);
      expect(builds, 1);

      notifier.toData('build');
      await tester.pump();
      expect(seen, <String?>['listen']);
      expect(builds, 2);
    });
  });

  group('AsyncNotifierConsumer.withData', () {
    testWidgets('renders and reports each status', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final events = <String>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierConsumer<ControllableAsyncNotifier, String>.withData(
            loadingBuilder: (child) => const Text('loading'),
            dataBuilder: (data, child) => Text('data $data'),
            errorBuilder: (error, child) => Text('error ${error.error}'),
            dataListener: (data) => events.add('data $data'),
            loadingListener: () => events.add('loading'),
            errorListener: (error) => events.add('error ${error.error}'),
          ),
        ),
      );

      expect(find.text('data initial'), findsOneWidget);

      notifier.toLoading();
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);

      notifier.toError('boom');
      await tester.pump();
      expect(find.text('error boom'), findsOneWidget);

      expect(events, <String>['loading', 'error boom']);
    });

    testWidgets('omitted listeners are allowed', (tester) async {
      final notifier = ControllableAsyncNotifier();

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierConsumer<ControllableAsyncNotifier, String>.withData(
            loadingBuilder: (child) => const Text('loading'),
            dataBuilder: (data, child) => Text('data $data'),
            errorBuilder: (error, child) => Text('error ${error.error}'),
          ),
        ),
      );

      notifier.toLoading();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('both predicates receive the unwrapped data', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final buildPairs = <List<String?>>[];
      final listenPairs = <List<String?>>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierConsumer<ControllableAsyncNotifier, String>.withData(
            loadingBuilder: (child) => const Text('loading'),
            dataBuilder: (data, child) => Text('data $data'),
            errorBuilder: (error, child) => Text('error ${error.error}'),
            buildWhen: (previous, current) {
              buildPairs.add(<String?>[previous, current]);
              return true;
            },
            listenWhen: (previous, current) {
              listenPairs.add(<String?>[previous, current]);
              return true;
            },
          ),
        ),
      );

      notifier.toData('second');
      await tester.pump();

      expect(buildPairs, <List<String?>>[
        <String?>['initial', 'second'],
      ]);
      expect(listenPairs, <List<String?>>[
        <String?>['initial', 'second'],
      ]);
    });
  });
}
