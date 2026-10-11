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

class ControllableAsyncNotifier extends AsyncNotifier<String> {
  ControllableAsyncNotifier() : super.withData('initial');

  AsyncState<String> get current => state as AsyncState<String>;

  final List<BaseAsyncState<String>> updates = <BaseAsyncState<String>>[];

  @override
  Future<AsyncState<String>> onInit() async => current;

  @override
  void onUpdate(BaseAsyncState<String> state) => updates.add(state);

  void toLoading() => setLoading();

  void toData(String data, {bool forced = false, bool notify = true}) {
    setData(data, forced: forced, notify: notify);
  }

  void toError(Object error, {String? message, StackTrace? stackTrace}) {
    setError(error, message: message, stackTrace: stackTrace);
  }

  void replace(
    AsyncState<String> next, {
    bool notify = true,
    bool forced = false,
    bool Function(String? curr, String? next)? equalityCheck,
  }) {
    setState(
      next,
      notify: notify,
      forced: forced,
      equalityCheck: equalityCheck,
    );
  }
}
