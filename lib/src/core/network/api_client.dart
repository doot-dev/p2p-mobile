import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'api_exception.dart';

/// Thin wrapper around [Dio] that:
///  * targets the Next.js REST API (`Env.apiBaseUrl + Env.apiPrefix`),
///  * attaches the current Firebase user's ID token on every request,
///  * normalises errors into [ApiException].
class ApiClient {
  ApiClient({Dio? dio, FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = '${Env.apiBaseUrl}${Env.apiPrefix}'
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 30)
      ..contentType = Headers.jsonContentType;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _auth.currentUser?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    if (Env.enableNetworkLogging) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final Dio _dio;
  final FirebaseAuth _auth;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _request<T>(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) =>
      _request<T>(() => _dio.post<T>(path, data: data));

  Future<T> patch<T>(String path, {Object? data}) =>
      _request<T>(() => _dio.patch<T>(path, data: data));

  Future<T> delete<T>(String path, {Object? data}) =>
      _request<T>(() => _dio.delete<T>(path, data: data));

  Future<T> _request<T>(Future<Response<T>> Function() send) async {
    try {
      final response = await send();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// App-wide singleton API client.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
