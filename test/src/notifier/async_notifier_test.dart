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

    test('setLoading keeps the data and clears the error', () {
      final notifier = ControllableAsyncNotifier()..toError('boom');

      notifier.toLoading();

      expect(notifier.current.isLoading, isTrue);
      expect(notifier.current.data, 'initial');
      expect(notifier.current.errorState, isNull);
    });

    test('setData replaces the value and reports it to onUpdate', () {
      final notifier = ControllableAsyncNotifier()..toData('next');

      expect(notifier.current.data, 'next');
      expect(notifier.updates.last.data, 'next');
    });

    test('setData with notify false still updates the state', () {
      final notifier = ControllableAsyncNotifier()
        ..toData('quiet', notify: false);

      expect(notifier.current.data, 'quiet');
    });

    test('setData forced accepts an unchanged value', () {
      final notifier = ControllableAsyncNotifier()
        ..toData('initial', forced: true);

      expect(notifier.updates.length, 1);
    });

    test('setError keeps the data and carries the error details', () {
      final stackTrace = StackTrace.current;
      final notifier = ControllableAsyncNotifier()
        ..toError('boom', message: 'failed', stackTrace: stackTrace);

      expect(notifier.current.hasError, isTrue);
      expect(notifier.current.data, 'initial');
      expect(notifier.current.errorState?.error, 'boom');
      expect(notifier.current.errorState?.message, 'failed');
      expect(notifier.current.errorState?.stackTrace, stackTrace);
    });

    test('a custom equalityCheck receives the unwrapped data', () {
      final notifier = ControllableAsyncNotifier();
      final pairs = <List<String?>>[];

      notifier.replace(
        const AsyncState<String>.data('second'),
        equalityCheck: (curr, next) {
          pairs.add(<String?>[curr, next]);
          return true;
        },
      );

      expect(pairs, <List<String?>>[
        <String?>['initial', 'second'],
      ]);
      expect(notifier.current.data, 'initial');
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
