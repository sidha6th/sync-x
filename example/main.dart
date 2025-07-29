import 'package:flutter/material.dart';
import 'package:syncx/syncx.dart';

void main() {
  runApp(const MyApp());
}

// Example Notifier: simple counter
class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  void increment() => setState(state + 1);
  void decrement() => setState(state - 1);
}

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

  Future<void> updateState() async {
    setState(state.toLoading());
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    final bool isSuccess = true; // Set to false to simulate error
    if (isSuccess) {
      return setState(state.toData('Success'));
    }

    // Replace 'errorObject' with your actual error object as needed
    // return setState(
    //   state.toError('..errorObject', message: 'Network call failed'),
    // );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NotifierRegister(
      create: (_) => CounterNotifier(),
      child: NotifierRegister(
        create: (_) => GreetingAsyncNotifier(),
        child: const MaterialApp(title: 'SyncX Example', home: HomeScreen()),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SyncX Example'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Counter'),
              Tab(text: 'Async'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [CounterNotifierTab(), AsyncNotifierTab()],
        ),
      ),
    );
  }
}

class CounterNotifierTab extends StatelessWidget {
  const CounterNotifierTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rebuilds only when the count changes
            NotifierBuilder<CounterNotifier, int>(
              buildWhen: (prev, curr) => prev != curr,
              builder: (context, count) => Text(
                'Count: $count',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),
            // Listen for side effects (e.g., show a SnackBar when count is even)
            NotifierListener<CounterNotifier, int>(
              listenWhen: (prev, curr) => curr % 2 == 0,
              listener: (count) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Count is even: $count')),
                );
              },
              child: const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            // Combine build and listen
            NotifierConsumer<CounterNotifier, int>(
              buildWhen: (prev, curr) => prev != curr,
              listenWhen: (prev, curr) => curr > prev,
              builder: (context, count) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () =>
                        context.read<CounterNotifier>().decrement(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        context.read<CounterNotifier>().increment(),
                  ),
                ],
              ),
              listener: (count) {
                debugPrint('Count increased: $count');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AsyncNotifierTab extends StatelessWidget {
  const AsyncNotifierTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AsyncNotifierBuilder<GreetingAsyncNotifier, String>(
          builder: (context, state) {
            return state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              data: (data) => Text(
                data,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              error: (error) => Text(
                'Error: ${error.message ?? error.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh_outlined),
        onPressed: () {
          context.read<GreetingAsyncNotifier>().updateState();
        },
      ),
    );
  }
}
