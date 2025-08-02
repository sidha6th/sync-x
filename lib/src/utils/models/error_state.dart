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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState &&
        other.error == error &&
        other.message == message &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(error, message, stackTrace);

  @override
  String toString() {
    return 'ErrorState(error: $error, message: $message, stackTrace: $stackTrace)';
  }
}
