import 'package:syncx/syncx.dart';

// Example AsyncNotifier: fetches a string after a delay
class GreetingAsyncNotifier extends AsyncNotifier<String> {
  GreetingAsyncNotifier() : super();

  @override
  Future<AsyncState<String>> onInit() {
    // Simulate async loading
    return Future.delayed(const Duration(seconds: 2), () {
      // Uncomment the next line to simulate an error:
      //  return const AsyncState.error(ErrorState('Failed to load greeting'));
      return const AsyncState.data('Hello from AsyncNotifier!');
    });
  }
}
