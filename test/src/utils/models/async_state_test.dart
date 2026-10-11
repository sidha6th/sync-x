import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

void main() {
  group('AsyncState construction', () {
    test('loading has no data and no error', () {
      const state = AsyncState<int>.loading();

      expect(state.isLoading, isTrue);
      expect(state.hasError, isFalse);
      expect(state.data, isNull);
      expect(state.errorState, isNull);
    });

    test('data holds its value and is neither loading nor error', () {
      const state = AsyncState<int>.data(7);

      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.data, 7);
      expect(state.errorState, isNull);
    });

    test('error wraps the error, message and stack trace', () {
      final stackTrace = StackTrace.current;
      final state = AsyncState<int>.error(
        'boom',
        message: 'failed',
        stackTrace: stackTrace,
      );

      expect(state.hasError, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorState?.error, 'boom');
      expect(state.errorState?.message, 'failed');
      expect(state.errorState?.stackTrace, stackTrace);
    });

    test('errorWithState takes an existing ErrorState', () {
      final error = ErrorState('boom', stackTrace: StackTrace.current);
      final state = AsyncState<int>.errorWithState(error);

      expect(state.hasError, isTrue);
      expect(state.errorState, error);
      expect(state.data, isNull);
    });
  });

  group('AsyncState.when', () {
    test('dispatches to loading', () {
      expect(
        const AsyncState<int>.loading().when(
          loading: () => 'loading',
          data: (data) => 'data $data',
          error: (e) => 'error',
        ),
        'loading',
      );
    });

    test('dispatches to data', () {
      expect(
        const AsyncState<int>.data(3).when(
          loading: () => 'loading',
          data: (data) => 'data $data',
          error: (e) => 'error',
        ),
        'data 3',
      );
    });

    test('dispatches to error', () {
      expect(
        AsyncState<int>.error('boom').when(
          loading: () => 'loading',
          data: (data) => 'data $data',
          error: (e) => 'error ${e.error}',
        ),
        'error boom',
      );
    });
  });

  group('AsyncState.whenData', () {
    test('calls data with the value', () {
      final seen = <int>[];

      const AsyncState<int>.data(3).whenData(seen.add);

      expect(seen, <int>[3]);
    });

    test('calls the optional loading callback', () {
      var called = false;

      const AsyncState<int>.loading().whenData(
        (_) {},
        loading: () => called = true,
      );

      expect(called, isTrue);
    });

    test('calls the optional error callback', () {
      ErrorState? seen;

      AsyncState<int>.error('boom').whenData(
        (_) {},
        error: (e) => seen = e,
      );

      expect(seen?.error, 'boom');
    });

    test('omitting the loading callback is allowed', () {
      expect(
        () => const AsyncState<int>.loading().whenData((_) {}),
        returnsNormally,
      );
    });

    test('omitting the error callback is allowed', () {
      expect(
        () => AsyncState<int>.error('boom').whenData((_) {}),
        returnsNormally,
      );
    });
  });

  group('AsyncState transitions', () {
    test('toLoading from loading', () {
      final next = const AsyncState<int>.loading().toLoading();

      expect(next.isLoading, isTrue);
      expect(next.data, isNull);
      expect(next.errorState, isNull);
    });

    test('toLoading from data keeps the data', () {
      final next = const AsyncState<int>.data(5).toLoading();

      expect(next.isLoading, isTrue);
      expect(next.data, 5);
      expect(next.errorState, isNull);
    });

    test('toLoading from error drops the error', () {
      final next = AsyncState<int>.error('boom').toLoading();

      expect(next.isLoading, isTrue);
      expect(next.errorState, isNull);
    });

    test('toData from loading', () {
      final next = const AsyncState<int>.loading().toData(1);

      expect(next.data, 1);
      expect(next.isLoading, isFalse);
      expect(next.errorState, isNull);
    });

    test('toData from data replaces the value', () {
      final next = const AsyncState<int>.data(1).toData(2);

      expect(next.data, 2);
    });

    test('toData from error clears the error', () {
      final next = AsyncState<int>.error('boom').toData(1);

      expect(next.data, 1);
      expect(next.hasError, isFalse);
      expect(next.errorState, isNull);
    });

    test('toError from loading', () {
      final next = const AsyncState<int>.loading().toError('boom');

      expect(next.hasError, isTrue);
      expect(next.errorState?.error, 'boom');
      expect(next.data, isNull);
    });

    test('toError from data keeps the data', () {
      final next = const AsyncState<int>.data(5).toError('boom');

      expect(next.hasError, isTrue);
      expect(next.data, 5);
    });

    test('toError from error replaces the error', () {
      final next = AsyncState<int>.error('first').toError(
        'second',
        message: 'failed',
        stackTrace: StackTrace.empty,
      );

      expect(next.errorState?.error, 'second');
      expect(next.errorState?.message, 'failed');
      expect(next.errorState?.stackTrace, StackTrace.empty);
    });
  });

  group('AsyncState equality', () {
    test('identical instances are equal', () {
      const state = AsyncState<int>.data(1);

      expect(state == state, isTrue);
    });

    test('same status and data are equal', () {
      expect(const AsyncState<int>.data(1), const AsyncState<int>.data(1));
      expect(
        const AsyncState<int>.data(1).hashCode,
        const AsyncState<int>.data(1).hashCode,
      );
    });

    test('different data is not equal', () {
      expect(
        const AsyncState<int>.data(1),
        isNot(const AsyncState<int>.data(2)),
      );
    });

    test('different status is not equal', () {
      expect(
        const AsyncState<int>.loading(),
        isNot(const AsyncState<int>.data(1)),
      );
    });

    test('different error is not equal', () {
      expect(AsyncState<int>.error('a'), isNot(AsyncState<int>.error('b')));
    });

    test('another type is not equal', () {
      expect(const AsyncState<int>.loading() == Object(), isFalse);
    });

    test('a different data type is not equal, in either direction', () {
      const narrow = AsyncState<int>.data(1);
      const wide = AsyncState<num>.data(1);

      expect(narrow == wide, isFalse);
      expect(wide == narrow, isFalse);
      expect(narrow.hashCode, isNot(wide.hashCode));
    });
  });

  group('AsyncState.toString', () {
    test('loading', () {
      expect(
        const AsyncState<int>.loading().toString(),
        'AsyncState<int>.loading()',
      );
    });

    test('data', () {
      expect(
        const AsyncState<int>.data(2).toString(),
        'AsyncState<int>.data(2)',
      );
    });

    test('error', () {
      expect(AsyncState<int>.error('boom').toString(), contains('boom'));
    });
  });
}
