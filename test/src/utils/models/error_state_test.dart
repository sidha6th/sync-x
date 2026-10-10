import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

void main() {
  group('ErrorState', () {
    test('holds the error with optional message and stack trace', () {
      final stackTrace = StackTrace.current;
      final state =
          ErrorState('boom', message: 'failed', stackTrace: stackTrace);

      expect(state.error, 'boom');
      expect(state.message, 'failed');
      expect(state.stackTrace, stackTrace);
    });

    test('message and stack trace default to null', () {
      const state = ErrorState('boom');

      expect(state.message, isNull);
      expect(state.stackTrace, isNull);
    });

    test('identical instances are equal', () {
      const state = ErrorState('boom');

      expect(state == state, isTrue);
    });

    test('equal field values are equal', () {
      const a = ErrorState('boom', message: 'failed');
      const b = ErrorState('boom', message: 'failed');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different error is not equal', () {
      expect(const ErrorState('a'), isNot(const ErrorState('b')));
    });

    test('a different message is not equal', () {
      expect(
        const ErrorState('a', message: 'x'),
        isNot(const ErrorState('a', message: 'y')),
      );
    });

    test('a different stack trace is not equal', () {
      expect(
        ErrorState('a', stackTrace: StackTrace.fromString('x')),
        isNot(ErrorState('a', stackTrace: StackTrace.fromString('y'))),
      );
    });

    test('another type is not equal', () {
      expect(const ErrorState('a') == Object(), isFalse);
    });

    test('toString names every field', () {
      const state = ErrorState('boom', message: 'failed');

      expect(state.toString(), contains('boom'));
      expect(state.toString(), contains('failed'));
    });
  });
}
