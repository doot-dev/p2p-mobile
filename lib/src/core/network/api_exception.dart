import 'package:dio/dio.dart';

/// A normalised error surfaced from the REST API so the UI never has to deal
/// with raw [DioException]s.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Builds a user-facing exception from a Dio error, preferring the server's
  /// `{ "error": "..." }` body when present.
  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;

    String? serverMessage;
    if (data is Map && data['error'] is String) {
      serverMessage = data['error'] as String;
    } else if (data is Map && data['message'] is String) {
      serverMessage = data['message'] as String;
    }

    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Could not reach the server. Check your connection.',
      _ => serverMessage ?? 'Something went wrong. Please try again.',
    };

    return ApiException(message, statusCode: response?.statusCode);
  }

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
