/// SyncX: A lightweight, developer-friendly state management solution for Flutter.
///
/// SyncX provides notifiers, builders, and consumers for reactive UI updates with minimal boilerplate.
/// Inspired by bloc, provider, and riverpod, it offers a familiar API for developers migrating from those solutions.
///
/// Features:
/// - Notifier-based state management
/// - Async and error state handling
/// - Builder and listener widgets for UI updates and side effects
/// - Provider integration and easy registration
///
/// See the package README and example for usage details.
library;

export 'package:provider/provider.dart';

export 'src/builders/notifier_builder.dart';
export 'src/builders/notifier_consumer.dart';
export 'src/builders/notifier_listener.dart';
export 'src/notifier/base/base_notifier.dart' show AsyncNotifier, Notifier;
export 'src/register/notifier_register.dart';
export 'src/utils/models/async_state.dart';
export 'src/utils/models/error_state.dart';
