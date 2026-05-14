sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'No internet connection']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Resource not found']);
}

class RateLimitException extends ApiException {
  const RateLimitException([super.message = 'Rate limit exceeded']);
}

class ServerException extends ApiException {
  final int? statusCode;
  const ServerException([super.message = 'Server error', this.statusCode]);
}

class ParseException extends ApiException {
  const ParseException([super.message = 'Failed to parse response']);
}
