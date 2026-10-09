import 'dart:async';

import 'package:syncx/syncx.dart';

class TestAsyncNotifier extends AsyncNotifier<String> {
  TestAsyncNotifier(this.completer);

  final Completer<AsyncState<String>> completer;

  AsyncState<String> get current => state as AsyncState<String>;

  @override
  Future<AsyncState<String>> onInit() => completer.future;
}

class ThrowingAsyncNotifier extends AsyncNotifier<String> {
  ThrowingAsyncNotifier(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  AsyncState<String> get current => state as AsyncState<String>;

  @override
  Future<AsyncState<String>> onInit() =>
      Future<AsyncState<String>>.error(error, stackTrace);
}
