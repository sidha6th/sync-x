/// Represents error information for an asynchronous operation.
class ErrorState {
  /// Creates an [ErrorState] with the given [error], optional [message], and [stackTrace].
  const ErrorState(this.error, {this.message, this.stackTrace});

  /// The error object.
  final Object error;

  /// An optional error message.
  final String? message;

  /// An optional stack trace associated with the error.
  final StackTrace? stackTrace;
}
