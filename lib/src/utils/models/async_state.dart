import 'package:syncx/src/utils/models/base/base_async_state.dart';
import 'package:syncx/src/utils/models/error_state.dart';

/// Represents the state of an asynchronous operation, encapsulating loading, data, and error states.
///
/// [AsyncState] is useful for managing UI state in response to async tasks such as network requests.
/// It provides factory constructors for loading, data, and error states, and utility methods to transition between them.
///
/// [S] is the type of data managed by the state.
base class AsyncState<S extends Object?> extends IAsyncState<S> {
  /// Creates a loading state.
  const AsyncState.loading() : _isLoading = true, super.loading();

  /// Creates a data state with the given [data].
  const AsyncState.data(super.data) : _isLoading = false, super.data();

  /// Creates an error state with the given [errorState].
  const AsyncState.error(super.errorState) : _isLoading = false, super.error();

  /// Internal constructor for custom state transitions.
  const AsyncState._({super.data, super.errorState, bool isLoading = false})
    : _isLoading = isLoading,
      super();

  /// Whether the state is currently loading.
  final bool _isLoading;

  bool get isLoading => _isLoading;
  bool get hasError => errorState != null;

  /// Returns a copy of this state with optional new values.
  AsyncState<S> _copyWith({S? data, ErrorState? errorState, bool? isLoading}) {
    return AsyncState<S>._(
      errorState: errorState,
      data: data ?? this.data,
      isLoading: isLoading ?? this._isLoading,
    );
  }

  /// Returns a new [AsyncState] representing the loading state.
  @override
  AsyncState<S> toLoading() {
    return _copyWith(isLoading: true);
  }

  /// Returns a new [AsyncState] with the given [data].
  @override
  AsyncState<S> toData(S data) {
    return _copyWith(isLoading: false, data: data);
  }

  /// Returns a new [AsyncState] with the given error information.
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

  @override
  T when<T>({
    required T Function() loading,
    required T Function(S data) data,
    required T Function(ErrorState e) error,
  }) {
    if (_isLoading) return loading();

    if (hasError) return error(errorState!);

    // ignore: null_check_on_nullable_type_parameter
    return data(this.data!);
  }
}
