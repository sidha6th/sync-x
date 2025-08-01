// Example AsyncNotifier: fetches a string after a delay
import 'package:syncx/syncx.dart';

class GreetingAsyncNotifier extends AsyncNotifier<String> {
  GreetingAsyncNotifier() : super();

  @override
  Future<AsyncState<String>> onInit() async {
    // Simulate async loading
    return Future.delayed(const Duration(seconds: 2), () {
      // Uncomment the next line to simulate an error:
      //  return const AsyncState.error(ErrorState('Failed to load greeting'));
      return const AsyncState.data('Hello from AsyncNotifier!');
    });
  }

  Future<void> updateState() async {
    setLoading();
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    final bool isSuccess = true; // Set to false to simulate error
    if (isSuccess) {
      return setData('Success');
    }

    // Replace 'errorObject' with your actual error object as needed
    // return setState(
    //   state.toError('..errorObject', message: 'Network call failed'),
    // );
  }
}
