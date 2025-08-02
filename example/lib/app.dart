import 'package:example/src/home/home.dart';
import 'package:example/src/home/notifier/counter_notifier.dart';
import 'package:example/src/home/notifier/greeting_async_notifier.dart';
import 'package:flutter/material.dart';
import 'package:syncx/syncx.dart';

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
