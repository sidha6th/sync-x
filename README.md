# SyncX

Flutter state management made easy: SyncX is a lightweight, flexible state management solution for Flutter. It provides notifiers, builders, and consumers for reactive UI updates with minimal boilerplate. SyncX is designed for developers who want a simple, composable, and powerful way to manage state in their Flutter apps.

> **Note:** The implementation and API of SyncX are inspired by popular state management solutions such as [bloc](https://pub.dev/packages/bloc), [provider](https://pub.dev/packages/provider), and [riverpod](https://pub.dev/packages/riverpod). Naming conventions and patterns are chosen to be developer-friendly, especially for those migrating from or familiar with these libraries.

---

## Table of Contents

- [Features](#features)
- [Core Concepts & Usage](#core-concepts--usage)
  - [Create a Notifier](#1-create-a-notifier)
  - [Register the Notifier](#2-register-the-notifier)
  - [Consume State with Builders & Listeners](#3-consume-state-with-builders--listeners)
  - [Invoking Notifier Methods](#4-invoking-notifier-methods)
  - [Lifecycle Methods](#5-lifecycle-methods)
- [Bad Practices / Don’ts](#bad-practices--donts)
- [Usage Patterns](#usage-patterns)
- [Future Plans](#future-plans)
- [Contributing](#contributing)
- [License](#license)

---

## Why SyncX?

- **Simple and familiar API** for Flutter state management, inspired by popular solutions like bloc, provider, and riverpod.
- **Reactive UI updates with rebuild control**: Widgets rebuild on state changes, with precise control over when they update using `buildWhen` and `listenWhen`.
- **Notifier pattern**: Cleanly separates business logic from UI code with lifecycle hooks for initialization and state change handling.
- **Effortless async state handling**: Easily manage loading, data, and error states with specialized async widgets and convenient `.withData` constructors.
- **Minimal boilerplate**: Quick to set up and easy to integrate into any Flutter project with comprehensive documentation and examples.

---

## Features

- 🔄 **Notifier-based state management**: Simple, extendable notifiers for your app's state.
- 🏗️ **Builder widgets**: Easily rebuild UI in response to state changes with fine-grained control.
- 👂 **Listener widgets**: React to state changes with side effects without rebuilding UI.
- 🪶 **Minimal boilerplate**: Focus on your app logic, not on wiring up state.
- ⚡ **Async state support**: Built-in support for loading, data, and error states in async flows.
- 🎯 **Convenient APIs**: `.withData` constructors for async widgets provide cleaner, more readable code.
- 🔄 **Lifecycle hooks**: `onInit` and `onUpdate` methods for initialization and state change handling.
- 🎛️ **Rebuild control**: `buildWhen` and `listenWhen` predicates for precise control over when widgets rebuild or trigger side effects.

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
  ///
  /// You can also override [onUpdate] to perform side effects when the state changes.
  @override
  void onInit(){
    // doSomething...
  }
  
  @override
  void onUpdate(int state) {
    // Handle state changes, logging, side effects, etc.
    print('State updated to: $state');
  }

  /// Increments the counter by 1 and notifies listeners.
  ///
  /// Use [setState] to update the state and notify any listening widgets.
  ///
  /// [setState] accepts several optional parameters:
  ///   - [notify] (default: true): Controls whether listeners are notified and the UI is rebuilt.
  ///   - [forced] (default: false): Forces the state update even if the value hasn't changed, useful for mutating iterable state.
  ///   - [equalityCheck] (optional): Custom function to determine if state has changed.
  void increment() => setState(state + 1);
  
  /// Example with custom parameters:
  void incrementSilently() => setState(state + 1, notify: false); // Update state silently without triggering a UI rebuild
  void forceUpdate() => setState(state, forced: true); // Updates the state bypassing the equality check.
}
```

For async state (loading/data/error):

```dart
/// Extend [AsyncNotifier] to handle async operations such as network calls 
/// to handle loading, data, and error states using [AsyncState].
class GreetingAsyncNotifier extends AsyncNotifier<String> {
  /// Creates a [GreetingAsyncNotifier] that starts in loading state.
  /// Use this when you want to start with loading and transition to data/error.
  GreetingAsyncNotifier() : super();

  /// Creates a [GreetingAsyncNotifier] with initial data.
  /// Use this when you have initial data and want to start in data state.
  GreetingAsyncNotifier.withData(String initialData) : super.withData(initialData);

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
    return const AsyncState.error('Failed to load greeting');
  }
  
  @override
  void onUpdate(BaseAsyncState<String> state) {
    // Handle async state changes, logging, side effects, etc.
    if (state.isLoading) {
      print('Started loading data');
    } else if (state.hasError) {
      print('Error occurred: ${state.errorState?.message}');
    } else if (state.data != null) {
      print('Data loaded: ${state.data}');
    }
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
    setLoading(); // Transitions to loading state
    // Consider this as a Network call
    await Future.delayed(const Duration(seconds: 2));
    final bool isSuccess = true; // Set to false to simulate error
    if (isSuccess) {
     return setData('Success'); // Transitions to data state
    } 
    setError('Network error', message: 'Network call failed'); // Transitions to error state
  }
  
  /// Example of using setData with custom parameters:
  void updateDataSilently(String newData) {
    setData(newData, notify: false); // Update state silently without triggering a UI rebuild
  }
  
  void forceDataUpdate(String newData) {
    setData(newData, forced: true); // Updates the state bypassing the equality check.
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

**Reusing Notifiers Across Navigation:**

SyncX supports reusing notifiers across navigation using `NotifierRegister.value()`:

```dart
NotifierRegister<CounterNotifier>(
  create: (context) => CounterNotifier()
  child: ...,
)

// When navigating to a new screen, pass notifier
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NotifierRegister.value(
      notifier: context.read<CounterNotifier>(),
      child: DetailScreen(),
    ),
  ),
)
```

This allows you to share state across different screens, preserve state during navigation, and pass notifiers to dialogs or other overlays.

### 3. Consume State with Builders & Listeners

**Rebuild UI on State Change:**

```dart
NotifierBuilder<CounterNotifier, int>(
  builder: (count, child) => Text('Count: $count'),
)
```

**Control rebuilds:**

```dart
NotifierBuilder<CounterNotifier, int>(
  buildWhen: (prev, curr) => prev != curr,
  builder: (count, child) => Text('Count: $count'),
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
  builder: (count, child) => Text('Count: $count'),
  listener: (count) => print('Count changed: $count'),
)
```

**Control rebuilds and listeners with predicates:**
```dart
NotifierBuilder<CounterNotifier, int>(
  buildWhen: (prev, curr) => curr % 2 == 0, // Only rebuild for even numbers
  builder: (count, child) => Text('Even Count: $count'),
)

NotifierListener<CounterNotifier, int>(
  listenWhen: (prev, curr) => curr > 10, // Only listen when count > 10
  listener: (count) => print('Count exceeded 10: $count'),
  child: MyWidget(),
)

NotifierConsumer<CounterNotifier, int>(
  buildWhen: (prev, curr) => prev != curr, // Only rebuild when state changes
  listenWhen: (prev, curr) => curr % 5 == 0, // Only listen for multiples of 5
  builder: (count, child) => Text('Count: $count'),
  listener: (count) => print('Count is multiple of 5: $count'),
)
```

**Async State Handling:**

SyncX provides specialized widgets for handling asynchronous state with convenient APIs for loading, data, and error states:

**AsyncNotifierBuilder** – Rebuilds UI based on async state changes:
```dart
// Direct usage with builder
AsyncNotifierBuilder<GreetingAsyncNotifier, String>(
  builder: (state, child) {
    return state.when(
      loading: () => const CircularProgressIndicator(),
      data: (greeting) => Text(greeting),
      error: (error) => Text('Error: ${error.message}'),
    );
  },
)
```
```dart
// Convenient usage with .withData constructor
AsyncNotifierBuilder<GreetingAsyncNotifier, String>.withData(
  loadingBuilder: (child) => const CircularProgressIndicator(),
  dataBuilder: (greeting, child) => Text(greeting),
  errorBuilder: (error, child) => Text('Error: ${error.message}'),
)
```

**AsyncNotifierConsumer** – Combines building and listening for side effects:
```dart
// Direct usage
AsyncNotifierConsumer<GreetingAsyncNotifier, String>(
  builder: (state, child) {
    return state.when(
      loading: () => const CircularProgressIndicator(),
      data: (greeting) => Text(greeting),
      error: (error) => Text('Error: ${error.message}'),
    );
  },
  listener: (state) {
    state.when(
      loading: () => print('Loading...'),
      data: (data) => print('Data loaded: $data'),
      error: (error) => print('Error: ${error.message}'),
    );
  },
)
```
```dart
// Convenient usage with .withData constructor
AsyncNotifierConsumer<GreetingAsyncNotifier, String>.withData(
  loadingBuilder: (child) => const CircularProgressIndicator(),
  dataBuilder: (greeting, child) => Text(greeting),
  errorBuilder: (error, child) => Text('Error: ${error.message}'),
  loadingListener: () => print('Started loading'),
  dataListener: (data) => print('Data loaded: $data'),
  errorListener: (error) => print('Error occurred: ${error.message}'),
)
```

**AsyncNotifierListener** – Listens for async state changes without rebuilding UI:
```dart
// Direct usage
AsyncNotifierListener<GreetingAsyncNotifier, String>(
  listener: (state) {
    state.when(
      loading: () => print('Loading...'),
      data: (data) => print('Data loaded: $data'),
      error: (error) => print('Error: ${error.message}'),
    );
  },
  child: MyWidget(),
)
```
```dart
// Convenient usage with .withData constructor
AsyncNotifierListener<GreetingAsyncNotifier, String>.withData(
  loadingListener: () => print('Started loading'),
  dataListener: (data) => print('Data loaded: $data'),
  errorListener: (error) => print('Error occurred: ${error.message}'),
  child: MyWidget(),
)
```

**Control rebuilds and listeners with predicates:**
```dart
AsyncNotifierBuilder<GreetingAsyncNotifier, String>.withData(
  loadingBuilder: (child) => const CircularProgressIndicator(),
  dataBuilder: (greeting, child) => Text(greeting),
  errorBuilder: (error, child) => Text('Error: ${error.message}'),
  buildWhen: (previous, current) => previous != current, // Only rebuild when data changes
)
```

**Key Benefits of `.withData` Constructors:**

The `.withData` constructors provide several advantages over the direct builder approach:

- **Cleaner API**: Separate callbacks for loading, data, and error states make the code more readable.
- **Type Safety**: Each callback receives the correct type (data for dataBuilder, ErrorState for errorBuilder).
- **Reduced Boilerplate**: No need to manually handle the `state.when()` pattern in every widget.
- **Consistent Patterns**: All async widgets (Builder, Consumer, Listener) follow the same `.withData` pattern.
- **Child Support**: Each builder receives an optional `child` parameter for better widget composition.

**Widget Hierarchy and Relationships:**

SyncX provides a consistent widget hierarchy for both sync and async state management:

**Sync Widgets:**
- `NotifierBuilder` – Rebuilds UI on state changes
- `NotifierListener` – Listens for side effects without rebuilding
- `NotifierConsumer` – Combines building and listening

**Async Widgets:**
- `AsyncNotifierBuilder` – Rebuilds UI on async state changes
- `AsyncNotifierListener` – Listens for async state side effects
- `AsyncNotifierConsumer` – Combines async building and listening

All widgets support:
- **Predicates**: `buildWhen` and `listenWhen` for fine-grained control
- **Initialization**: `onInit` callback for widget-level setup
- **Child Composition**: Optional `child` parameter for widget composition

**Callback Signatures:**

**Builder Callbacks:**
```dart
// Sync widgets
Widget Function(S state, Widget? child)

// Async widgets (direct usage)
Widget Function(BaseAsyncState<S> state, Widget? child)

// Async widgets (.withData usage)
Widget Function(Widget? child) // loadingBuilder
Widget Function(S data, Widget? child) // dataBuilder  
Widget Function(ErrorState error, Widget? child) // errorBuilder
```

**Listener Callbacks:**
```dart
// Sync widgets
void Function(S state)

// Async widgets (direct usage)
void Function(BaseAsyncState<S> state)

// Async widgets (.withData usage)
void Function() // loadingListener
void Function(S data) // dataListener
void Function(ErrorState error) // errorListener
```

**Predicate Callbacks:**
```dart
// Sync widgets
bool Function(S previous, S current)

// Async widgets (.withData usage)
bool Function(S? previous, S? current) // Only compares data, not full state
```

**Widget Initialization with `onInit`:**

All SyncX widgets support an optional `onInit` callback that is invoked when the widget is first created:

```dart
// Sync widgets
NotifierBuilder<CounterNotifier, int>(
  onInit: (notifier) {
    // Custom initialization logic
    print('Widget initialized with notifier: $notifier');
  },
  builder: (count, child) => Text('Count: $count'),
)
```
```dart
// Async widgets
AsyncNotifierBuilder<GreetingAsyncNotifier, String>.withData(
  onInit: (notifier) {
    // Custom initialization logic
    print('Async widget initialized with notifier: $notifier');
  },
  loadingBuilder: (child) => const CircularProgressIndicator(),
  dataBuilder: (greeting, child) => Text(greeting),
  errorBuilder: (error, child) => Text('Error: ${error.message}'),
)
```

### 4. Invoking Notifier Methods

To invoke a method inside your notifier (for example, to increment the counter), use the context extension or provider pattern in your widget. Here's how you can call a notifier method from a button press:

```dart
ElevatedButton(
  onPressed: () => context.read<CounterNotifier>().increment(),
  child: const Text('Increment'),
)
```

This will call the `increment` method on your `CounterNotifier` and update the state accordingly.

### 5. Lifecycle Methods

SyncX provides lifecycle methods that you can override in your notifiers:

**`onInit()`** - Called when the notifier is first created and attached to the widget tree:
```dart
@override
void onInit() {
  // Initialize resources, start listeners, etc.
  print('Notifier initialized');
}
```

**`onUpdate(state)`** - Called when the notifier's state changes:
```dart
@override
void onUpdate(int state) {
  // Handle state changes, logging, side effects, etc.
  print('State updated to: $state');
}
```

**For AsyncNotifier, `onInit()` returns a Future:**
```dart
@override
Future<AsyncState<String>> onInit() async {
  // Fetch initial data
  final data = await _fetchData();
  return AsyncState.data(data);
}

@override
void onUpdate(BaseAsyncState<String> state) {
  // Handle async state changes
  if (state.isLoading) {
    print('Started loading data');
  } else if (state.hasError) {
    print('Error occurred: ${state.errorState?.message}');
  } else if (state.data != null) {
    print('Data loaded: ${state.data}');
  }
}
```

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
- **Convenient Async APIs**: Use `.withData` constructors on async widgets for cleaner, more readable code.
- **Lifecycle Management**: Override `onInit` and `onUpdate` methods for initialization and state change handling.

---

## Future Plans

- **Top-level observer support** to monitor state changes across the app.
- **Enhanced debugging tools** for better development experience.
- **Performance optimizations** for large-scale applications.

---

## Contributing

Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/sidha6th/sync-x).

---

## License

This project is licensed under the [MIT License](LICENSE).

---

If you have questions or need help, please open an issue or start a discussion on [GitHub](https://github.com/sidha6th/sync-x).
