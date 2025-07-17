# SyncX

A lightweight, flexible state management solution for Flutter, providing notifiers, builders, and consumers for reactive UI updates with minimal boilerplate. SyncX is inspired by simplicity and composability, making it easy to manage state in your Flutter apps.

> **Note:** The implementation and API of SyncX are inspired by popular state management solutions such as [bloc](https://pub.dev/packages/bloc), [provider](https://pub.dev/packages/provider), and [riverpod](https://pub.dev/packages/riverpod). Naming conventions and patterns are chosen to be developer-friendly, especially for those migrating from or familiar with these libraries.

---

## Features

- 🔄 **Notifier-based state management**: Simple, extendable notifiers for your app's state.
- 🏗️ **Builder widgets**: Easily rebuild UI in response to state changes.
- 👂 **Listener widgets**: React to state changes with side effects.
- 🪶 **Minimal boilerplate**: Focus on your app logic, not on wiring up state.
- ⚡ **Async state support**: Built-in support for loading, data, and error states in async flows.

---

## Getting Started

Add SyncX to your `pubspec.yaml`:

```yaml
dependencies:
  syncx: ^0.0.3
```

Then run:

```sh
flutter pub get
```

---

## Core Concepts & Usage

### 1. Create a Notifier

A Notifier holds and updates your state:

```dart
class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);
  void increment() => setState(state + 1);
}
```

For async state (loading/data/error):

```dart
class GreetingAsyncNotifier extends AsyncNotifier<String> {
  GreetingAsyncNotifier() : super();

  @override
  Future<AsyncState<String>> onInit() async {
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    if (success...) {
      return const AsyncState.data('Hello from AsyncNotifier!');
    }
    return const AsyncState.error(ErrorState('Failed to load greeting'));
  }
}
```

### 2. Register the Notifier

Register your notifier at the root of your widget tree:

```dart
NotifierRegister<CounterNotifier, int>(
  create: (_) => CounterNotifier(),
  child: MyApp(),
)
```

You can nest registers for multiple notifiers:

```dart
NotifierRegister<CounterNotifier, int>(
  create: (_) => CounterNotifier(),
  child: NotifierRegister<GreetingAsyncNotifier, AsyncState<String>>(
    create: (_) => GreetingAsyncNotifier(),
    child: MyApp(),
  ),
)
```

### 3. Consume State with Builders & Listeners

**Rebuild UI on State Change:**

```dart
NotifierBuilder<CounterNotifier, int>(
  builder: (context, count) => Text('Count: $count'),
)
```

**Control rebuilds:**

```dart
NotifierBuilder<CounterNotifier, int>(
  buildWhen: (prev, curr) => prev != curr,
  builder: (context, count) => Text('Count: $count'),
)
```

**Listen for Side Effects:**

```dart
NotifierListener<CounterNotifier, int>(
  listenWhen: (prev, curr) => curr % 2 == 0,
  listener: (count) => print('Count is even: $count'),
  child: MyWidget(),
)
```

**Combine Build and Listen:**

```dart
NotifierConsumer<CounterNotifier, int>(
  builder: (context, count) => Text('Count: $count'),
  listener: (count) => print('Count changed: $count'),
)
```

**Async State Handling:**

```dart
NotifierBuilder<GreetingAsyncNotifier, AsyncState<String>>(
  builder: (context, state) => state.when(
    loading: () => CircularProgressIndicator(),
    data: (greeting) => Text(greeting),
    error: (e) => Text('Error: ${e.message ?? e.error}'),
  ),
)
```

---

## Usage Patterns

- **Rebuild UI on State Change**: Use `NotifierBuilder` with `buildWhen` for fine-grained rebuild control.
- **Listen for Side Effects**: Use `NotifierListener` with `listenWhen` for side-effect logic.
- **Combine Build and Listen**: Use `NotifierConsumer` for both UI and side effects.
- **Async State Handling**: Use `AsyncNotifier` and `AsyncState` for loading, data, and error flows.

---

## Future Plans

- **Built-in stream support in notifiers** for easy loading and error state management.
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
