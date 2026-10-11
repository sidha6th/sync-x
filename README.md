# SyncX

State management for Flutter built on one idea: a notifier holds your state, widgets rebuild when it changes, and you control exactly when.

```dart
class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  void increment() => setState(state + 1);
}
```

No code generation, no build runner, no annotations. One dependency (`provider`). The whole library is under 1500 lines.

## Install

```bash
flutter pub add syncx
```

```dart
import 'package:syncx/syncx.dart';
```

## A counter, start to finish

```dart
import 'package:flutter/material.dart';
import 'package:syncx/syncx.dart';

class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  void increment() => setState(state + 1);
}

void main() {
  runApp(
    NotifierRegister(
      create: (context) => CounterNotifier(),
      child: const MaterialApp(home: CounterPage()),
    ),
  );
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: NotifierBuilder<CounterNotifier, int>(
          builder: (count, child) => Text('$count'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CounterNotifier>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

That is the entire loop: `setState` to change state, `NotifierRegister` to provide it, `NotifierBuilder` to render it, `context.read` to call methods on it.

## The widgets

| Widget | Rebuilds UI | Runs side effects |
|---|---|---|
| `NotifierBuilder` | yes | no |
| `NotifierListener` | no | yes |
| `NotifierConsumer` | yes | yes |
| `AsyncNotifierBuilder` | yes | no |
| `AsyncNotifierListener` | no | yes |
| `AsyncNotifierConsumer` | yes | yes |

Every one of them accepts:

| Parameter | Type | Purpose |
|---|---|---|
| `builder` | `(state, child) => Widget` | What to render |
| `listener` | `(state) => void` | Side effects: navigation, snackbars, logging |
| `buildWhen` | `(previous, current) => bool` | Skip the rebuild when false |
| `listenWhen` | `(previous, current) => bool` | Skip the listener when false |
| `onInit` | `(notifier) => void` | Widget-level setup, once |
| `child` | `Widget?` | Passed to `builder`, not rebuilt with it |

`buildWhen` compares against what is currently on screen. `listenWhen` compares against the previous notification. Neither is consulted on the first build.

## Controlling rebuilds

```dart
NotifierBuilder<CounterNotifier, int>(
  buildWhen: (previous, current) => current.isEven,
  builder: (count, child) => Text('$count'),
)

NotifierListener<CounterNotifier, int>(
  listenWhen: (previous, current) => current > 10,
  listener: (count) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Past ten: $count')),
  ),
  child: const MyForm(),
)
```

A rejected `buildWhen` costs one predicate call and nothing else — no rebuild, no allocation. A `NotifierListener` with no `builder` never rebuilds its subtree at all, so the `child` above is built once no matter how often the count changes.

## Async state

`AsyncNotifier` models loading, data and error as one value. Return the initial state from `onInit`:

```dart
class GreetingNotifier extends AsyncNotifier<String> {
  GreetingNotifier(this.api);

  final GreetingApi api;

  @override
  Future<AsyncState<String>> onInit() async {
    return AsyncState.data(await api.fetch());
  }

  Future<void> refresh() async {
    setLoading();
    try {
      setData(await api.fetch());
    } catch (error, stackTrace) {
      setError(error, message: 'Could not load', stackTrace: stackTrace);
    }
  }
}
```

A thrown error inside `onInit` becomes an error state automatically — you do not need to catch it there.

Render it with named callbacks per state:

```dart
AsyncNotifierBuilder<GreetingNotifier, String>.withData(
  loadingBuilder: (child) => const CircularProgressIndicator(),
  dataBuilder: (greeting, child) => Text(greeting),
  errorBuilder: (error, child) => Text(error.message ?? '${error.error}'),
)
```

Or handle the state yourself, which is the same thing one level lower:

```dart
AsyncNotifierBuilder<GreetingNotifier, String>(
  builder: (state, child) => state.when(
    loading: () => const CircularProgressIndicator(),
    data: (greeting) => Text(greeting),
    error: (error) => Text(error.message ?? '${error.error}'),
  ),
)
```

`AsyncNotifierListener` and `AsyncNotifierConsumer` take the same `.withData` shape, with `loadingListener`, `dataListener` and `errorListener`.

**Keeping the old value during a refresh.** `setLoading()` and `setError()` preserve the previous `data`, so a refresh does not have to blank the screen. `when` and `whenData` branch on status alone and will not hand it back — read `state.data` directly:

```dart
AsyncNotifierBuilder<GreetingNotifier, String>(
  builder: (state, child) => state.when(
    loading: () => Text(state.data ?? 'Loading...'),
    data: (greeting) => Text(greeting),
    error: (error) => Text(state.data ?? 'Failed'),
  ),
)
```

## Sharing a notifier across screens

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NotifierRegister.value(
      notifier: context.read<CounterNotifier>(),
      child: const DetailPage(),
    ),
  ),
)
```

`NotifierRegister.value` does not own the notifier, so it will not dispose it when the route pops.

## Lifecycle

```dart
class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  @override
  void onInit() {}

  @override
  void onUpdate(int state) {}
}
```

`onInit` runs once, when the notifier is constructed. `onUpdate` runs after every accepted state change, before listeners are notified. For `AsyncNotifier`, `onInit` is `Future<AsyncState<S>>` and its result becomes the state.

## Gotchas

**Pass dependencies through the constructor's initializer list, not its body.** Dart runs a superclass constructor body before the subclass's, and that is where `onInit` starts. A field assigned in your own constructor body is still unset inside `onInit`:

```dart
// Wrong: repository is null inside onInit
class UserNotifier extends Notifier<User?> {
  UserNotifier() : super(null) {
    repository = UserRepository();
  }

  UserRepository? repository;

  @override
  void onInit() => repository!.load(); // throws
}

// Right
class UserNotifier extends Notifier<User?> {
  UserNotifier(this.repository) : super(null);

  final UserRepository repository;

  @override
  void onInit() => repository.load();
}
```

**Do not call `onInit` yourself.** It already ran by the time any widget builds. The widgets' `onInit` parameter is for your own setup:

```dart
onInit: (notifier) => notifier.onInit(),   // duplicate initialization
onInit: (notifier) => notifier.loadMore(), // what it is for
```

**Use `setState`, never `notifyListeners`.** The latter throws, by design — it would update listeners without updating state.

**`setState` ignores unchanged state.** Pass `forced: true` when you mutate a list or map in place and the reference has not changed, or `notify: false` to update state without rebuilding.

## Roadmap

- A top-level observer for watching state changes across the app
- Debugging tools
- `BaseAsyncState` folded into `AsyncState`, in the next breaking release

## Links

- [Example app](https://github.com/sidha6th/sync-x/tree/master/example)
- [API reference](https://pub.dev/documentation/syncx/latest/)
- [Issues](https://github.com/sidha6th/sync-x/issues)
- [Changelog](https://github.com/sidha6th/sync-x/blob/master/CHANGELOG.md)

MIT licensed. The API borrows naming from [bloc](https://pub.dev/packages/bloc), [provider](https://pub.dev/packages/provider) and [riverpod](https://pub.dev/packages/riverpod), so patterns from those carry over.
