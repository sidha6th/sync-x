import 'package:syncx/src/utils/models/error_state.dart';

/// Abstract base class for representing asynchronous state.
///
/// [IAsyncState] provides a common interface for loading, data, and error states.
///
/// [S] is the type of data managed by the state.
abstract class IAsyncState<S extends Object?> {
  /// Creates an [IAsyncState] with optional [data] and [errorState].
  const IAsyncState({this.data, this.errorState});

  /// Creates a data state with the given [data].
  const IAsyncState.data(this.data) : errorState = null;

  /// Creates a loading state.
  const IAsyncState.loading()
      : data = null,
        errorState = null;

  /// Creates an error state with the given [errorState].
  const IAsyncState.error(ErrorState this.errorState) : data = null;

  /// Returns a new state representing an error with the given [error].
  IAsyncState<S> toError(
    Object error, {
    String? message,
    StackTrace? stackTrace,
  });

  /// Returns a new state representing the loading state.
  IAsyncState<S> toLoading();

  /// Returns a new state with the given [data].
  IAsyncState<S> toData(S data);

  /// The data held by the state, if any.
  final S? data;

  /// The error information held by the state, if any.
  final ErrorState? errorState;

  T when<T>({
    required T Function() loading,
    required T Function(S data) data,
    required T Function(ErrorState e) error,
  });
}
