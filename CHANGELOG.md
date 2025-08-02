## 0.0.98

- Features: New Async notifier API's setLoading, setError and setData.
- Refactored base notifier builder classes for better structure and clarity
- Example: Simplified error handling in GreetingAsyncNotifier.
           Updated import paths for async and counter notifier tabs.

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
