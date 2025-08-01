import 'package:example/src/home/notifier/counter_notifier.dart';
import 'package:flutter/material.dart';
import 'package:syncx/syncx.dart';

class CounterNotifierTab extends StatelessWidget {
  const CounterNotifierTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rebuilds only when the count changes
          NotifierConsumer<CounterNotifier, int>(
            listenWhen: (_, count) => count != 0 && count % 2 == 0,
            listener: (count) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              messenger.showSnackBar(
                SnackBar(content: Text('Count is even: $count')),
              );
            },
            buildWhen: (prev, curr) => prev != curr,
            builder: (count) => Text(
              'Count: $count',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => context.read<CounterNotifier>().decrement(),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.read<CounterNotifier>().increment(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
