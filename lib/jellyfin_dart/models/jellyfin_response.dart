/// Generic response wrapper for Jellyfin API calls
class JellyfinResponse<T> {
  final T? data;
  final String? message;
  final int statusCode;
  final bool isSuccess;
  final Object? error;

  const JellyfinResponse._({
    this.data,
    this.message,
    required this.statusCode,
    required this.isSuccess,
    this.error,
  });

  /// Create a successful response
  factory JellyfinResponse.success({
    required T data,
    required int statusCode,
  }) {
    return JellyfinResponse._(
      data: data,
      statusCode: statusCode,
      isSuccess: true,
    );
  }

  /// Create an error response
  factory JellyfinResponse.error({
    required String message,
    required int statusCode,
    Object? error,
  }) {
    return JellyfinResponse._(
      message: message,
      statusCode: statusCode,
      isSuccess: false,
      error: error,
    );
  }

  /// Get data or throw exception if error
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw JellyfinException(message ?? 'Unknown error', statusCode, error);
  }

  /// Get data or return null if error
  T? get dataOrNull => isSuccess ? data : null;
}

/// Custom exception for Jellyfin API errors
class JellyfinException implements Exception {
  final String message;
  final int statusCode;
  final Object? originalError;

  const JellyfinException(this.message, this.statusCode, this.originalError);

  @override
  String toString() => 'JellyfinException($statusCode): $message';
}
