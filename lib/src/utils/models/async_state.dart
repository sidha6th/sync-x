import 'package:syncx/src/utils/models/base/base_async_state.dart';
import 'package:syncx/src/utils/models/error_state.dart';

/// Represents the state of an asynchronous operation, encapsulating loading, data, and error states.
///
/// [AsyncState] is useful for managing UI state in response to async tasks such as network requests,
/// database operations, or any operation that can be in a loading, success, or error state.
///
/// [S] is the type of data managed by the state.
///
/// This class provides factory constructors for loading, data, and error states, and utility methods
/// to transition between them. It also implements pattern matching via [when] for ergonomic UI code.
class AsyncState<S extends Object?> extends BaseAsyncState<S> {
  /// Creates a loading state.
  ///
  /// Use this when the asynchronous operation is in progress.
  const AsyncState.loading()
      : _isLoading = true,
        super.loading();

  /// Creates a data state with the given [data].
  ///
  /// Use this when the asynchronous operation has completed successfully and you have data to provide.
  const AsyncState.data(super.data)
      : _isLoading = false,
        super.data();

  /// Creates an error state with the given [errorState].
  ///
  /// Use this when the asynchronous operation has failed and you want to provide error details.
  const AsyncState.error(super.errorState)
      : _isLoading = false,
        super.error();

  /// Internal constructor for custom state transitions.
  ///
  /// [data] is the data to hold, if any.
  /// [errorState] is the error information, if any.
  /// [isLoading] indicates whether the state is loading.
  const AsyncState._({super.data, super.errorState, bool isLoading = false})
      : _isLoading = isLoading,
        super();

  /// Whether the state is currently loading.
  final bool _isLoading;

  /// Returns true if the state is loading.
  @override
  bool get isLoading => _isLoading;

  /// Returns true if the state represents an error.
  @override
  bool get hasError => errorState != null;

  /// Returns a new [AsyncState] representing the loading state.
  ///
  /// Use this to transition to a loading state from any other state.
  @override
  AsyncState<S> toLoading() {
    return _copyWith(isLoading: true);
  }

  /// Returns a new [AsyncState] with the given [data].
  ///
  /// Use this to transition to a data state from any other state.
  @override
  AsyncState<S> toData(S data) {
    return _copyWith(isLoading: false, data: data);
  }

  /// Returns a new [AsyncState] with the given error information.
  ///
  /// [error] is the error object or exception.
  /// [message] is an optional error message.
  /// [stackTrace] is an optional stack trace for debugging.
  ///
  /// Use this to transition to an error state from any other state.
  @override
  AsyncState<S> toError(
    Object error, {
    String? message,
    StackTrace? stackTrace,
  }) {
    return _copyWith(
      isLoading: false,
      errorState: ErrorState(error, message: message, stackTrace: stackTrace),
    );
  }

  /// Pattern matching for async state.
  ///
  /// [loading] is called if the state is loading.
  /// [data] is called if the state contains data.
  /// [error] is called if the state contains an error.
  ///
  /// Returns the result of the matching callback.
  @override
  T when<T>({
    required T Function() loading,
    required T Function(S data) data,
    required T Function(ErrorState e) error,
  }) {
    if (_isLoading) return loading();

    if (hasError) return error(errorState!);

    return data(this.data as S);
  }

  /// Returns a copy of this state with optional new values.
  ///
  /// [data] is the new data to hold, if any.
  /// [errorState] is the new error information, if any.
  /// [isLoading] indicates whether the new state is loading.
  ///
  /// This is used internally for state transitions.
  AsyncState<S> _copyWith({S? data, ErrorState? errorState, bool? isLoading}) {
    return AsyncState<S>._(
      errorState: errorState,
      data: data ?? this.data,
      isLoading: isLoading ?? this._isLoading,
    );
  }
}
