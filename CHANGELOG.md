## 0.2.0

- **Fix**: `listenWhen` received a `previous` value that never advanced, so every comparison after the first was made against the state the widget mounted with. It now receives the state immediately before the change it is being asked about.
- **Fix**: `NotifierBuilder` and `NotifierConsumer` kept the `child` and the `builder` closure from the build in which they first rebuilt, so a changed `child` or a rebuilt parent could render stale output.
- **Fix**: Replacing the notifier instance provided above a builder, which `NotifierRegister.value` allows, left the widget listening to the old notifier for the rest of its life.
- **Fix**: `buildWhen` was consulted once during the initial build, comparing the initial state against itself, so a predicate with side effects fired before any change had occurred.
- **Fix**: `AsyncNotifier` could notify listeners and overwrite state after disposal when `onInit` completed late, and an `onInit` that failed was swallowed instead of becoming an error state.
- **Fix**: A custom `equalityCheck` passed to `AsyncNotifier.setState` was combined with the default state equality rather than replacing it, so a check reporting "equal, do not update" still updated whenever any other field differed.
- **Fix**: A widget's `onInit` callback could not call a notifier method that updates state synchronously. `NotifierRegister` subscribed to the notifier, so a state change during a descendant's `initState` marked the provider dirty mid-build and threw `setState() or markNeedsBuild() called during build`. The notifier is now provided without being subscribed to, since the builders attach their own listeners. This also removes one listener and one provider rebuild per state change.
- **Note**: Because `NotifierRegister` no longer subscribes to the notifier, `context.watch<MyNotifier>()` and `Provider.of(listen: true)` no longer rebuild on state changes. Use `NotifierBuilder`, `NotifierConsumer` or their async equivalents, which is what the package documents.
- **Fix**: `AsyncState` equality ignored its type argument, so `AsyncState<int>.data(1)` equalled `AsyncState<num>.data(1)` and an update that legitimately changed the state's type could be silently refused.
- **Enhancement**: `state` is now public. `context.read<MyNotifier>().state` was previously an analyzer error for every consumer of the package.
- **Enhancement**: `addListener` and `removeListener` are no longer marked protected, so a notifier can be wired to widgets other than SyncX's own.
- **Docs**: `Notifier` and `AsyncNotifier` now document that dependencies must arrive as initializing formals or through the initializer list, because `onInit` runs before the subclass constructor body.
- **Docs**: `toLoading` and `toError` now document that the previous `data` carries over and is read through the `data` field, since `when` and `whenData` branch on status alone.
- **Docs**: Corrected builder snippets that still showed the pre-0.1.9 `(context, state)` signature, and two `onUpdate` examples that named the override `onUpdated`.
- **Internal**: 100% line coverage, enforced in CI alongside formatting, `--fatal-infos` analysis and a publish dry run.

## 0.1.9

- **BREAKING CHANGE**: Modified builder callback signatures from `(context, state)` to `(state, child)` for all widgets (`NotifierBuilder`, `NotifierConsumer`, `AsyncNotifierBuilder`, `AsyncNotifierConsumer`). This change improves consistency and removes unnecessary context parameter.
- **Feature**: Added new `onUpdate` lifecycle API for notifiers to handle state changes and side effects.
- **Feature**: Enhanced async widgets with `.withData` constructors for cleaner, more readable async state handling.
- **Feature**: Improved `AsyncNotifierBuilder`, `AsyncNotifierConsumer`, and `AsyncNotifierListener` with convenient APIs.
- **Enhancement**: Better type safety and reduced boilerplate for async state management.
- **Internal**: Performance improvements and code optimizations.

**Migration Guide:**
Update your builder callbacks from:
```dart
// Old API (0.0.x)
NotifierBuilder<MyNotifier, MyState>(
  builder: (context, state) => Text('$state'),
)

// New API (0.1.0+)
NotifierBuilder<MyNotifier, MyState>(
  builder: (state, child) => Text('$state'),
)
```

## 0.0.97

- Fix: Resolved minor bugs
- Features: New Async notifier API's setLoading, setError and setData.

## 0.0.93

- Added and expanded documentation for async widgets (`AsyncNotifierBuilder`, `AsyncNotifierConsumer`, `AsyncNotifierListener`) and core async state model(`AsyncState`).
- Updated README: clarified async state handling, added examples for new async widgets, and explained their relationship to sync widgets.
- Fix: Notifier builder bug

## 0.0.83

- Updated: Description.

## 0.0.82

- Improved documentation and made minor formatting adjustments.

## 0.0.81

- Improved documentation and made minor formatting adjustments.

## 0.0.8 

- Updated: Documentation.

## 0.0.7

- Updated: Documentation patch.

## 0.0.6

- Updated: Documentation for clarity and completeness, including improved usage examples and API explanations.

## 0.0.5

- Updated: Example

## 0.0.4

- Fix: Format

## 0.0.3

- Lowered Dart SDK minimum version to >=2.17.0 for broader compatibility with more Flutter projects.
- Updated pubspec and documentation to reflect compatibility improvements.

## 0.0.2

- Improved async state handling: `AsyncNotifier` now supports async `onInit` returning a Future.
- Updated documentation and README for clarity and conciseness.
- Example app refactored for modularity and better demonstration of both sync and async notifiers.
- Minor API and doc improvements for lifecycle mixins and async state.

## 0.0.1

- Initial release of SyncX.
- Notifier-based state management for Flutter.
- `BaseNotifier` and `Notifier` classes for state logic.
- `NotifierRegister` for easy provider integration.
- `NotifierBuilder` for rebuilding UI on state changes.
- `NotifierListener` for side-effect listening.
- `NotifierConsumer` for combined build and listen.
- Fine-grained rebuild/listen control with `buildWhen` and `listenWhen`.
- Full documentation and usage examples.
- MIT License.
