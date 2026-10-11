import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../../helpers/async_host.dart';
import '../../../helpers/test_async_notifier.dart';

void main() {
  group('AsyncNotifierBuilder', () {
    testWidgets('builds from the raw state', (tester) async {
      final notifier = ControllableAsyncNotifier();

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierBuilder<ControllableAsyncNotifier, String>(
            builder: (state, child) => Text(state.data ?? 'none'),
          ),
        ),
      );

      expect(find.text('initial'), findsOneWidget);
    });

    testWidgets('buildWhen gates the rebuild', (tester) async {
      final notifier = ControllableAsyncNotifier();
      var builds = 0;

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierBuilder<ControllableAsyncNotifier, String>(
            buildWhen: (previous, current) => current.data == 'keep',
            builder: (state, child) {
              builds++;
              return Text(state.data ?? 'none');
            },
          ),
        ),
      );
      expect(builds, 1);

      notifier.toData('skip');
      await tester.pump();
      expect(builds, 1);

      notifier.toData('keep');
      await tester.pump();
      expect(builds, 2);
      expect(find.text('keep'), findsOneWidget);
    });
  });

  group('AsyncNotifierBuilder.withData', () {
    Widget build(ControllableAsyncNotifier notifier, {Widget? child}) {
      return hostAsync(
        notifier,
        AsyncNotifierBuilder<ControllableAsyncNotifier, String>.withData(
          loadingBuilder: (child) => const Text('loading'),
          dataBuilder: (data, child) => Text('data $data'),
          errorBuilder: (error, child) => Text('error ${error.error}'),
        ),
      );
    }

    testWidgets('renders each status in turn', (tester) async {
      final notifier = ControllableAsyncNotifier();

      await tester.pumpWidget(build(notifier));
      expect(find.text('data initial'), findsOneWidget);

      notifier.toLoading();
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);

      notifier.toData('fresh');
      await tester.pump();
      expect(find.text('data fresh'), findsOneWidget);

      notifier.toError('boom');
      await tester.pump();
      expect(find.text('error boom'), findsOneWidget);

      notifier.toData('recovered');
      await tester.pump();
      expect(find.text('data recovered'), findsOneWidget);
    });

    testWidgets('buildWhen receives the unwrapped data', (tester) async {
      final notifier = ControllableAsyncNotifier();
      final pairs = <List<String?>>[];

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierBuilder<ControllableAsyncNotifier, String>.withData(
            loadingBuilder: (child) => const Text('loading'),
            dataBuilder: (data, child) => Text('data $data'),
            errorBuilder: (error, child) => Text('error ${error.error}'),
            buildWhen: (previous, current) {
              pairs.add(<String?>[previous, current]);
              return true;
            },
          ),
        ),
      );

      notifier.toData('second');
      await tester.pump();

      expect(pairs, <List<String?>>[
        <String?>['initial', 'second'],
      ]);
    });

    testWidgets('passes the child through to each branch', (tester) async {
      final notifier = ControllableAsyncNotifier();

      await tester.pumpWidget(
        hostAsync(
          notifier,
          AsyncNotifierBuilder<ControllableAsyncNotifier, String>.withData(
            loadingBuilder: (child) => child ?? const Text('no child'),
            dataBuilder: (data, child) => child ?? const Text('no child'),
            errorBuilder: (error, child) => child ?? const Text('no child'),
          ),
        ),
      );

      expect(find.text('no child'), findsOneWidget);
    });
  });
}
