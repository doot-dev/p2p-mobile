import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart' show XFile;

/// Build-time config. Override per run:
///   flutter run --dart-define=API_BASE_URL=https://api.example.com
abstract class Env {
  static const _override = String.fromEnvironment('API_BASE_URL');
  static const production = 'https://api.pitchtopicture.in';

  /// P2P-backend origin (serves /api/auth and /api/ptp).
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return production;
    // The Android emulator reaches the host machine at 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }
}

/// P2P-backend answers `{ success, message, data }`; callers get `data`.
dynamic unwrapEnvelope(dynamic body) => body is Map && body.containsKey('success') ? body['data'] : body;

/// User-facing API error: the server's `message` (for a 422, the first field error).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// Null when the server was never reached (offline, timeout).
  final int? statusCode;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final server = data is Map && data['message'] is String ? data['message'] as String : null;
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError => 'Could not reach the server. Check your connection.',
      _ => server ?? 'Something went wrong. Please try again.',
    };
    return ApiException(message, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}

/// Access + refresh tokens: cached in memory, persisted in the Keychain / Keystore
/// (encrypted browser storage on web).
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  String? access;
  String? refresh;

  Future<void> load() async {
    access = await _storage.read(key: 'access_token');
    refresh = await _storage.read(key: 'refresh_token');
  }

  Future<void> save(String accessToken, String refreshToken) async {
    access = accessToken;
    refresh = refreshToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clear() async {
    access = null;
    refresh = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

/// Dio wrapper: attaches the access token, and on a 401 refreshes once (shared by
/// concurrent requests) and retries. If the refresh fails, [onSessionExpired] fires.
class ApiClient {
  ApiClient(this.tokens) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokens.access;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (e, handler) async {
          final options = e.requestOptions;
          final canRefresh = e.response?.statusCode == 401 &&
              options.extra['retried'] != true &&
              !_noRefreshPaths.contains(options.path) &&
              tokens.refresh != null;
          if (!canRefresh) return handler.next(e);

          final fresh = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
          if (fresh == null) {
            onSessionExpired?.call();
            return handler.next(e);
          }
          options
            ..extra['retried'] = true
            ..headers['Authorization'] = 'Bearer $fresh';
          try {
            handler.resolve(await _dio.fetch(options));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  static const _noRefreshPaths = {'/api/auth/login', '/api/auth/register', '/api/auth/refresh'};

  final TokenStore tokens;
  VoidCallback? onSessionExpired;
  Future<String?>? _refreshing;

  final _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  );

  /// Returns the new access token, or null if the session is over.
  Future<String?> _refresh() async {
    try {
      final res = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
          .post('/api/auth/refresh', data: {'refreshToken': tokens.refresh});
      final session = unwrapEnvelope(res.data) as Map;
      await tokens.save(session['accessToken'] as String, session['refreshToken'] as String);
      return tokens.access;
    } on DioException catch (e) {
      // Only a rejected token ends the session; being offline doesn't.
      if (e.response?.statusCode == 401) await tokens.clear();
      return null;
    }
  }

  Future<dynamic> get(String path) => _send(() => _dio.get(path));

  Future<dynamic> post(String path, [Object? data]) => _send(() => _dio.post(path, data: data ?? {}));

  Future<dynamic> put(String path, Object? data) => _send(() => _dio.put(path, data: data));

  Future<dynamic> patch(String path, Object? data) => _send(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  /// Uploads a file straight to MinIO with a presigned POST and returns the value to save on the record.
  /// kinds: 'profilePhoto' | 'projectImage' (JPEG/PNG/WebP, 5 MB) · 'script' (PDF, 20 MB; private, the
  /// value is a `minio:` reference the server turns into a short-lived link for the owner only).
  Future<String> upload(XFile file, {required String kind}) async {
    final type = kind == 'script' ? 'application/pdf' : (file.mimeType ?? _imageType(file.name));
    final presign = await post('/api/ptp/v1/uploads/presign', {'kind': kind, 'contentType': type}) as Map<String, dynamic>;
    final form = FormData.fromMap({
      ...(presign['fields'] as Map).cast<String, dynamic>(),
      // S3 requires the file to be the last field.
      'file': MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name, contentType: DioMediaType.parse(type)),
    });
    try {
      await Dio().post(presign['url'] as String, data: form);
    } on DioException catch (e) {
      final tooBig = '${e.response?.data}'.contains('EntityTooLarge');
      final what = kind == 'script' ? 'script' : 'image';
      final max = kind == 'script' ? '20 MB' : '5 MB';
      throw ApiException(tooBig ? 'The $what is too large (max $max).' : 'Could not upload the $what.', statusCode: e.response?.statusCode);
    }
    return presign['value'] as String;
  }

  static String _imageType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', _ => 'image/jpeg' };
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return unwrapEnvelope((await request()).data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStoreProvider)));
