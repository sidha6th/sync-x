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
/// The class supports equality comparison and provides readable string representations for debugging.
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

  /// Creates an error state with the given error information.
  ///
  /// [error] is the error object or exception that occurred.
  /// [message] is an optional error message for display.
  /// [stackTrace] is an optional stack trace for debugging.
  ///
  /// Use this when the asynchronous operation has failed and you want to provide error details.
  AsyncState.error(
    Object error, {
    String? message,
    StackTrace? stackTrace,
  })  : _isLoading = false,
        super.error(
          ErrorState(error, message: message, stackTrace: stackTrace),
        );

  /// Creates an error state with an existing [ErrorState].
  ///
  /// [errorState] is the error information to use.
  ///
  /// Use this when you already have an [ErrorState] object and want to create an error state.
  const AsyncState.errorWithState(
    super.errorState,
  )   : _isLoading = false,
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
  AsyncState<S> toLoading() => _copyWith(isLoading: true);

  /// Returns a new [AsyncState] with the given [data].
  ///
  /// Use this to transition to a data state from any other state.
  @override
  AsyncState<S> toData(S data) => AsyncState.data(data);

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
      errorState: ErrorState(
        error,
        message: message,
        stackTrace: stackTrace,
      ),
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

  /// Optional pattern matching for async state, focused on data extraction.
  ///
  /// [data] is called if the state contains data and is required.
  /// [loading] is an optional callback for loading state.
  /// [error] is an optional callback for error state.
  ///
  /// This method is useful when you primarily care about the data and want optional
  /// handling for loading and error states. All callbacks are void functions.
  ///
  /// Example:
  /// ```dart
  /// state.whenData(
  ///   data: (data) => print('Data: $data'),
  ///   loading: () => print('Loading...'),
  ///   error: (error) => print('Error: ${error.message}'),
  /// );
  /// ```
  @override
  void whenData<T>(
    void Function(S data) data, {
    void Function()? loading,
    void Function(ErrorState e)? error,
  }) {
    if (_isLoading) return loading?.call();

    if (hasError) return error?.call(errorState!);

    return data(this.data as S);
  }

  /// Returns a copy of this state with optional new values.
  ///
  /// [data] is the new data to hold, if any.
  /// [isLoading] indicates whether the new state is loading.
  /// [errorState] is the new error information, if any.
  ///
  /// This is used internally for state transitions.
  AsyncState<S> _copyWith({
    S? data,
    bool? isLoading,
    ErrorState? errorState,
  }) {
    return AsyncState<S>._(
      errorState: errorState,
      data: data ?? this.data,
      isLoading: isLoading ?? this._isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsyncState<S> &&
        other._isLoading == _isLoading &&
        other.data == data &&
        other.errorState == errorState;
  }

  @override
  int get hashCode => Object.hash(_isLoading, data, errorState);

  @override
  String toString() {
    if (_isLoading) return 'AsyncState<$S>.loading()';

    if (hasError) return 'AsyncState<$S>.error($errorState)';

    return 'AsyncState<$S>.data($data)';
  }
}
