part of '../async_state.dart';

/// Abstract base class for representing asynchronous state in a notifier or state management flow.
///
/// [BaseAsyncState] provides a common interface for handling loading, data, and error states
/// in asynchronous operations, such as network requests or background computations.
///
/// [S] is the type of data managed by the state.
///
/// This class is typically extended or implemented by concrete async state classes.
/// It enables pattern matching via [when] and [whenData], and provides utility constructors and methods
/// for transitioning between loading, data, and error states.
abstract class BaseAsyncState<S extends Object?> {
  /// Creates a [BaseAsyncState] with optional [data] and [errorState].
  ///
  /// This constructor is typically used by subclasses.
  const BaseAsyncState({
    required AsyncStatus status,
    this.data,
    this.errorState,
  }) : _status = status;

  /// Creates a data state with the given [data].
  ///
  /// Use this when the asynchronous operation has completed successfully and you have data to provide.
  const BaseAsyncState.data(this.data)
      : errorState = null,
        _status = AsyncStatus.data;

  /// Creates a loading state.
  ///
  /// Use this when the asynchronous operation is in progress.
  const BaseAsyncState.loading()
      : data = null,
        errorState = null,
        _status = AsyncStatus.loading;

  /// Creates an error state with the given [errorState].
  ///
  /// Use this when the asynchronous operation has failed and you want to provide error details.
  const BaseAsyncState.error(this.errorState)
      : data = null,
        _status = AsyncStatus.error;

  /// Returns a new state representing an error with the given [error].
  ///
  /// [error] is the error object or exception.
  /// [message] is an optional error message.
  /// [stackTrace] is an optional stack trace for debugging.
  ///
  /// Use this to transition to an error state from any other state.
  AsyncState<S> toError(
    Object error, {
    String? message,
    StackTrace? stackTrace,
  });

  /// Returns a new state representing the loading state.
  ///
  /// Use this to transition to a loading state from any other state.
  AsyncState<S> toLoading();

  /// Returns a new state with the given [data].
  ///
  /// Use this to transition to a data state from any other state.
  AsyncState<S> toData(S data);

  /// The data held by the state, if any.
  ///
  /// This is non-null only in the data state.
  final S? data;

  /// The error information held by the state, if any.
  ///
  /// This is non-null only in the error state.
  final ErrorState? errorState;

  /// Returns true if the state is loading.
  bool get isLoading => _status == AsyncStatus.loading;

  /// Returns true if the state represents an error.
  bool get hasError => _status == AsyncStatus.error;

  /// The status of the state.
  final AsyncStatus _status;

  /// Pattern matching for async state.
  ///
  /// [loading] is called if the state is loading.
  /// [data] is called if the state contains data.
  /// [error] is called if the state contains an error.
  ///
  /// Returns the result of the matching callback.
  /// All callbacks are required and must be provided.
  T when<T>({
    required T Function() loading,
    required T Function(S data) data,
    required T Function(ErrorState e) error,
  });

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
  void whenData<T>(
    void Function(S data) data, {
    void Function()? loading,
    void Function(ErrorState e)? error,
  });
}

/// The status of the state.
enum AsyncStatus {
  loading,
  data,
  error,
}
