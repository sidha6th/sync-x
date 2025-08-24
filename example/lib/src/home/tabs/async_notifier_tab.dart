import 'package:example/src/home/notifier/greeting_async_notifier.dart';
import 'package:flutter/material.dart';
import 'package:syncx/syncx.dart';

class AsyncNotifierTab extends StatelessWidget {
  const AsyncNotifierTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncNotifierBuilder<GreetingAsyncNotifier, String>.withData(
        dataBuilder: (data, child) {
          return Center(
            child: Text(
              data,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          );
        },
        loadingBuilder: (child) =>
            const Center(child: CircularProgressIndicator.adaptive()),
        errorBuilder: (error, child) => Center(
          child: Text(
            'Error: ${error.message ?? error.error}',
            style: const TextStyle(color: Colors.red),
          ),
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
