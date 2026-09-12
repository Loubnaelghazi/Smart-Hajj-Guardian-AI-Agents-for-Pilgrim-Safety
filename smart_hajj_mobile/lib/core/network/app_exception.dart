class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.uncertain = false});
  final String message;
  final int? statusCode;
  final bool uncertain;
  factory AppException.status(int? status) => AppException(switch (status) {
    400 || 422 =>
      'Some details could not be accepted. Refresh your trip and try again.',
    401 ||
    403 => 'Your session cannot access this information. Please sign in again.',
    404 => 'This information is no longer available. Refresh your trip.',
    409 =>
      'This request conflicts with an existing record. Refresh and try again.',
    429 => 'Guardian is receiving too many requests. Please wait a moment.',
    _ => 'Guardian connection unavailable. Please try again.',
  }, statusCode: status);
  @override
  String toString() => message;
}
