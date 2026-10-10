import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../../helpers/async_host.dart';
import '../../../helpers/test_async_notifier.dart';

void main() {
  group('AsyncNotifierListener', () {
    testWidgets('listens to the raw state', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final seen = <String?>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierListener<ControllableAsyncNotifier, String>(
            listener: (state) => seen.add(state.data),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.toData('next');
      await tester.pump();

      expect(seen, <String?>['next']);
    });

    testWidgets('listenWhen gates the listener', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final seen = <String?>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierListener<ControllableAsyncNotifier, String>(
            listenWhen: (previous, current) => current.data == 'keep',
            listener: (state) => seen.add(state.data),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.toData('skip');
      notifier.toData('keep');
      await tester.pump();

      expect(seen, <String?>['keep']);
    });
  });

  group('AsyncNotifierListener.withData', () {
    testWidgets('routes each status to its own callback', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final events = <String>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierListener<ControllableAsyncNotifier, String>.withData(
            dataListener: (data) => events.add('data $data'),
            loadingListener: () => events.add('loading'),
            errorListener: (error) => events.add('error ${error.error}'),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.toLoading();
      notifier.toData('fresh');
      notifier.toError('boom');
      await tester.pump();

      expect(events, <String>['loading', 'data fresh', 'error boom']);
    });

    testWidgets('omitted callbacks are allowed', (tester) async {
      final notifier = ControllableAsyncNotifier();

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierListener<ControllableAsyncNotifier, String>.withData(
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.toLoading();
      notifier.toData('fresh');
      notifier.toError('boom');
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('listenWhen receives the unwrapped data', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final pairs = <List<String?>>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierListener<ControllableAsyncNotifier, String>.withData(
            listenWhen: (previous, current) {
              pairs.add(<String?>[previous, current]);
              return false;
            },
            dataListener: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );

      notifier.toData('second');
      await tester.pump();

      expect(pairs, <List<String?>>[
        <String?>['initial', 'second'],
      ]);
    });
  });
}
