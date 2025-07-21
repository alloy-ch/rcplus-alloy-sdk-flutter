class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    return 'ApiException: $message (Status code: $statusCode, Body: $body)';
  }
}
