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
