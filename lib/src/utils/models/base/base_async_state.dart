import 'package:syncx/src/utils/models/error_state.dart';

/// Abstract base class for representing asynchronous state in a notifier or state management flow.
///
/// [BaseAsyncState] provides a common interface for handling loading, data, and error states
/// in asynchronous operations, such as network requests or background computations.
///
/// [S] is the type of data managed by the state.
///
/// This class is typically extended or implemented by concrete async state classes.
/// It enables pattern matching via [when], and provides utility constructors and methods
/// for transitioning between loading, data, and error states.
abstract class BaseAsyncState<S extends Object?> {
  /// Creates a [BaseAsyncState] with optional [data] and [errorState].
  ///
  /// This constructor is typically used by subclasses.
  const BaseAsyncState({this.data, this.errorState});

  /// Creates a data state with the given [data].
  ///
  /// Use this when the asynchronous operation has completed successfully and you have data to provide.
  const BaseAsyncState.data(this.data) : errorState = null;

  /// Creates a loading state.
  ///
  /// Use this when the asynchronous operation is in progress.
  const BaseAsyncState.loading()
      : data = null,
        errorState = null;

  /// Creates an error state with the given [errorState].
  ///
  /// Use this when the asynchronous operation has failed and you want to provide error details.
  const BaseAsyncState.error(ErrorState this.errorState) : data = null;

  /// Returns a new state representing an error with the given [error].
  ///
  /// [error] is the error object or exception.
  /// [message] is an optional error message.
  /// [stackTrace] is an optional stack trace for debugging.
  ///
  /// Use this to transition to an error state from any other state.
  BaseAsyncState<S> toError(
    Object error, {
    String? message,
    StackTrace? stackTrace,
  });

  /// Returns a new state representing the loading state.
  ///
  /// Use this to transition to a loading state from any other state.
  BaseAsyncState<S> toLoading();

  /// Returns a new state with the given [data].
  ///
  /// Use this to transition to a data state from any other state.
  BaseAsyncState<S> toData(S data);

  /// The data held by the state, if any.
  ///
  /// This is non-null only in the data state.
  final S? data;

  /// The error information held by the state, if any.
  ///
  /// This is non-null only in the error state.
  final ErrorState? errorState;

  /// Whether the state represents a loading state.
  bool get isLoading;

  /// Whether the state represents an error state.
  bool get hasError;

  /// Pattern matching for async state.
  ///
  /// [loading] is called if the state is loading.
  /// [data] is called if the state contains data.
  /// [error] is called if the state contains an error.
  ///
  /// Returns the result of the matching callback.
  T when<T>({
    required T Function() loading,
    required T Function(S data) data,
    required T Function(ErrorState e) error,
  });
}
