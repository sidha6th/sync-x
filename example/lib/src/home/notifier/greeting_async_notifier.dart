// Example AsyncNotifier: fetches a string after a delay
import 'package:syncx/syncx.dart';

class GreetingAsyncNotifier extends AsyncNotifier<String> {
  GreetingAsyncNotifier() : super();

  int count = 0;

  @override
  Future<AsyncState<String>> onInit() async {
    // Simulate async loading
    return Future.delayed(const Duration(seconds: 2), () {
      // Uncomment the next line to simulate an error:
      // return AsyncState.error('Failed to load greeting');
      return const AsyncState.data('Hello from AsyncNotifier!');
    });
  }

  Future<void> updateState() async {
    count++;
    setLoading();
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    if (count % 2 == 0) {
      return setData('Refreshed Successfully');
    }
    return setError('Failed to refresh', message: 'Failed to refresh');
  }
}
