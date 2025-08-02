import 'package:example/src/home/tabs/async_notifier_tab.dart';
import 'package:example/src/home/tabs/counter_notifier_tab.dart';
import 'package:flutter/material.dart';

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
              Tab(text: 'Counter Notifier'),
              Tab(text: 'Async Notifier'),
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
