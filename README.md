# SyncX

Flutter state management made easy: SyncX is a lightweight, flexible state management solution for Flutter. It provides notifiers, builders, and consumers for reactive UI updates with minimal boilerplate. SyncX is designed for developers who want a simple, composable, and powerful way to manage state in their Flutter apps.

> **Note:** The implementation and API of SyncX are inspired by popular state management solutions such as [bloc](https://pub.dev/packages/bloc), [provider](https://pub.dev/packages/provider), and [riverpod](https://pub.dev/packages/riverpod). Naming conventions and patterns are chosen to be developer-friendly, especially for those migrating from or familiar with these libraries.

---

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
- [Core Concepts & Usage](#core-concepts--usage)
  - [Create a Notifier](#1-create-a-notifier)
  - [Register the Notifier](#2-register-the-notifier)
  - [Consume State with Builders & Listeners](#3-consume-state-with-builders--listeners)
  - [Invoking Notifier Methods](#4-invoking-notifier-methods)
- [Bad Practices / Don’ts](#bad-practices--donts)
- [Usage Patterns](#usage-patterns)
- [Future Plans](#future-plans)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- 🔄 **Notifier-based state management**: Simple, extendable notifiers for your app's state.
- 🏗️ **Builder widgets**: Easily rebuild UI in response to state changes.
- 👂 **Listener widgets**: React to state changes with side effects.
- 🪶 **Minimal boilerplate**: Focus on your app logic, not on wiring up state.
- ⚡ **Async state support**: Built-in support for loading, data, and error states in async flows.

---

## Why use SyncX?

- **Flutter state management** with a familiar and easy-to-use API.
- Inspired by and compatible with popular libraries like **provider**, **bloc**, and **riverpod**.
- **Reactive UI updates**: Automatically rebuild widgets when state changes.
- **Notifier pattern**: Clean separation of business logic and UI.
- **Async state handling**: Effortlessly manage loading, data, and error states.
- **Minimal setup**: Get started quickly with little boilerplate.
- **Composable**: Easily combine multiple notifiers and consumers.
- **Great for migration**: If you’re coming from provider, bloc, or riverpod, you’ll feel right at home.

---

## Getting Started

Add SyncX to your `pubspec.yaml`:

```yaml
dependencies:
  syncx: ^0.0.5
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

/// Extend [Notifier] for basic state management
/// update state and notify listeners using [setState].
class CounterNotifier extends Notifier<int> {
  /// Creates a [CounterNotifier] with an initial state of 0.
  CounterNotifier() : super(0);

  /// Optionally override [onInit] to perform initialization logic when the notifier is first created.
  ///
  /// This method is called automatically once the instance is created.
  /// Use it to initialize resources or start listeners if needed.
  @override
  void onInit(){
    // doSomething...
  }

  /// Increments the counter by 1 and notifies listeners.
  ///
  /// Use [setState] to update the state and notify any listening widgets.
  ///
  /// [setState] also accepts two optional parameters:
  ///   - [forced] (default: false): Forces the state update even if the value hasn't changed, useful for manipulating iterable state.
  ///   - [notify] (default: true): Controls whether listeners are notified and the UI is rebuilt.
  void increment() => setState(state + 1);
}
```

For async state (loading/data/error):

```dart
/// Extend [AsyncNotifier] to handle async operations such as network calls 
/// to handle loading, data, and error states using [AsyncState].
class GreetingAsyncNotifier extends AsyncNotifier<String> {
  /// Creates a [GreetingAsyncNotifier] with an initial state.
  GreetingAsyncNotifier() : super();

  /// Called when the notifier is first initialized.
  ///
  /// This method is called automatically once the instance is created.
  ///
  /// It simulates a network call by delaying for 2 seconds.
  /// If the operation is successful, it returns an [AsyncState.data] with a greeting message.
  /// Otherwise, it returns an [AsyncState.error] with an error message.
  @override
  Future<AsyncState<String>> onInit() async {
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    final bool isSuccess = true; // Set to false to simulate error
    if (isSuccess) {
      return const AsyncState.data('Hello from AsyncNotifier!');
    }
    return const AsyncState.error(ErrorState('Failed to load greeting'));
  }

  /// Updates the state by simulating an asynchronous operation.
  ///
  /// This method demonstrates how to manually set the state to loading,
  /// perform an async task, and then update the state to either data or error.
  ///
  /// - Sets the state to loading before starting the async operation.
  /// - If successful, sets the state to data with a success message.
  /// - If failed, sets the state to error with an error object and message.
  Future<void> updateState() async {
    setState(state.toLoading());
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    final bool isSuccess = true; // Set to false to simulate error
    if (isSuccess) {
      return setState(state.toData('Success'));
    }

    // Replace 'errorObject' with your actual error object as needed
    return setState(
      state.toError('..errorObject', message: 'Network call failed'),
    );
  }
}
```

### 2. Register the Notifier

Register your notifier at the root of your widget tree:

```dart
NotifierRegister(
  create: (context) => CounterNotifier(),
  child: MyApp(),
)
```

You can nest registers for multiple notifiers:

```dart
NotifierRegister(
  create: (context) => CounterNotifier(),
  child: NotifierRegister(
    create: (context) => GreetingAsyncNotifier(),
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

### 4. Invoking Notifier Methods

To invoke a method inside your notifier (for example, to increment the counter), use the context extension or provider pattern in your widget. Here’s how you can call a notifier method from a button press:

```dart
ElevatedButton(
  onPressed: () => context.read<CounterNotifier>().increment(),
  child: const Text('Increment'),
)
```

This will call the `increment` method on your `CounterNotifier` and update the state accordingly.

---

### Bad Practices / Don’ts

- **Don’t:** Do not call the notifier’s `onInit` manually from builder, consumer, or listener `onInit` callbacks. This will result in duplicate initialization and unexpected behavior. The `onInit` method inside your notifier will be called automatically once the notifier instance is created. You do not need to call it yourself.

  **Incorrect usage example:**
  ```dart
  NotifierBuilder<Notifier, State>(
    // Do NOT do this:
    onInit: (notifier) => notifier.onInit(),
    // Do this if you need to call your own custom initialization logic when the widget is created:
    onInit: (notifier) => notifier.doSomethingElse(),
    builder: (context, state) => Text('State: $state'),
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
