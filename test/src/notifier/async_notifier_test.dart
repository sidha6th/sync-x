import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

import '../../helpers/test_async_notifier.dart';

void main() {
  group('AsyncNotifier', () {
    test('starts in the loading state', () {
      final notifier = TestAsyncNotifier(Completer<AsyncState<String>>());

      expect(notifier.current.isLoading, isTrue);
    });

    test('onInit resolving to data becomes the state', () async {
      final completer = Completer<AsyncState<String>>();
      final notifier = TestAsyncNotifier(completer);

      completer.complete(const AsyncState<String>.data('ready'));
      await completer.future;
      await Future<void>.delayed(Duration.zero);

      expect(notifier.current.data, 'ready');
    });

    test('onInit throwing becomes an error state carrying the error', () async {
      final stackTrace = StackTrace.current;
      final notifier = ThrowingAsyncNotifier('boom', stackTrace);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.current.hasError, isTrue);
      expect(notifier.current.errorState?.error, 'boom');
      expect(notifier.current.errorState?.stackTrace, stackTrace);
    });

    test('disposing before onInit completes does not throw or notify',
        () async {
      final completer = Completer<AsyncState<String>>();
      final notifier = TestAsyncNotifier(completer);

      notifier.dispose();
      completer.complete(const AsyncState<String>.data('late'));
      await completer.future;
      await Future<void>.delayed(Duration.zero);
    });
  });
}
