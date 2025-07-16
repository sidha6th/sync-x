# SyncX

A lightweight, flexible state management solution for Flutter, providing notifiers, builders, and consumers for reactive UI updates with minimal boilerplate. SyncX is inspired by simplicity and composability, making it easy to manage state in your Flutter apps.

> **Note:** The implementation and API of SyncX are inspired by popular state management solutions such as [bloc](https://pub.dev/packages/bloc), [provider](https://pub.dev/packages/provider), and [riverpod](https://pub.dev/packages/riverpod). Naming conventions and patterns are chosen to be developer-friendly, especially for those migrating from or familiar with these libraries.

---

## Features

- 🔄 **Notifier-based state management**: Simple, extendable notifiers for your app's state.
- 🏗️ **Builder widgets**: Easily rebuild UI in response to state changes.
- 👂 **Listener widgets**: React to state changes with side effects.
- 🪶 **Minimal boilerplate**: Focus on your app logic, not on wiring up state.

---

## Getting Started

Add SyncX to your `pubspec.yaml`:

```yaml
dependencies:
  syncx: ^0.0.1
```

Then run:

```sh
flutter pub get
```

---

## Usage

### 1. Create a Notifier

Extend `Notifier<T>` or `BaseNotifier<T>` to define your state logic:

```dart
import 'package:syncx/syncx.dart';

class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  void increment() => setState(state + 1);
}
```

### 2. Register the Notifier

Wrap your widget tree with `NotifierRegister`:

```dart
NotifierRegister<CounterNotifier, int>(
  create: (_) => CounterNotifier(),
  child: MyApp(),
)
```

### 3. Consume the Notifier

#### a) Rebuild UI on State Change

You can control when the UI rebuilds using the `buildWhen` parameter:

```dart
NotifierBuilder<CounterNotifier, int>(
  buildWhen: (previous, current) => previous != current, // Only rebuild if state actually changes
  builder: (context, count) => Text('Count: $count'),
)
```

#### b) Listen for State Changes (side effects)

You can control when the listener is triggered using the `listenWhen` parameter:

```dart
NotifierListener<CounterNotifier, int>(
  listenWhen: (previous, current) => current % 2 == 0, // Only listen when count is even
  listener: (count) => print('Count changed to even: $count'),
  child: MyWidget(),
)
```

#### c) Combine Build and Listen

You can use both `buildWhen` and `listenWhen` for fine-grained control:

```dart
NotifierConsumer<CounterNotifier, int>(
  buildWhen: (previous, current) => previous != current, // Only rebuild if state actually changes
  listenWhen: (previous, current) => current > previous, // Only listen when count increases
  builder: (context, count) => Text('Count: $count'),
  listener: (count) => print('Count increased: $count'),
)
```

---

## Future Plans

- **Built-in async and stream support in notifiers** for easy loading and error state management.
- **Top-level observer support** to monitor state changes across the app.
- **Migrate dependency injection (DI) from provider to a custom DI implementation** for more flexibility and control.

---

## Contributing

Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/sidha6th/sync-x).

---

## License

This project is licensed under the [MIT License](LICENSE).

---

If you have questions or need help, please open an issue or start a discussion on [GitHub](https://github.com/sidha6th/sync-x).
