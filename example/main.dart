import 'package:flutter/material.dart';
import 'package:syncx/syncx.dart';

import 'async_notifier_example.dart';
import 'counter_notifier_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NotifierRegister<CounterNotifier, int>(
      create: (_) => CounterNotifier(),
      child: NotifierRegister<GreetingAsyncNotifier, AsyncState<String>>(
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
    return Center(
      child: NotifierBuilder<GreetingAsyncNotifier, AsyncState<String>>(
        builder: (context, state) => state.when(
          loading: () => const CircularProgressIndicator(),
          data: (greeting) =>
              Text(greeting, style: Theme.of(context).textTheme.headlineMedium),
          error: (e) => Text(
            'Error: ${e.message ?? e.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
