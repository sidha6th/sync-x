import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

class _InitializerListDependency extends Notifier<int> {
  _InitializerListDependency(this.step) : super(0);

  final int step;

  @override
  void onInit() => setState(state + step);
}

class _ConstructorBodyDependency extends Notifier<int> {
  _ConstructorBodyDependency() : super(0) {
    step = 5;
  }

  int? step;
  int? stepSeenByOnInit;

  @override
  void onInit() => stepSeenByOnInit = step;
}

void main() {
  group('Notifier construction contract', () {
    test('a dependency passed through super is visible in onInit', () {
      expect(_InitializerListDependency(3).state, 3);
    });

    test('a dependency assigned in the constructor body is not', () {
      final notifier = _ConstructorBodyDependency();

      expect(notifier.stepSeenByOnInit, isNull);
      expect(notifier.step, 5);
    });
  });

  group('state visibility', () {
    test('state is readable from outside the notifier', () {
      expect(_InitializerListDependency(2).state, 2);
    });
  });
}
