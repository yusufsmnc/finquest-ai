import 'package:dio/dio.dart';

import 'auth/token_storage.dart';

/// Single Dio instance for the whole app. Widgets never touch this directly —
/// only the `data/` repositories do.
///
/// - Base URL comes from `--dart-define=API_BASE_URL=...` (never hardcoded).
/// - A request interceptor attaches `Authorization: Bearer <token>` when a
///   token exists.
/// - A response/error interceptor clears the token and notifies the auth layer
///   on a 401 so the app can drop back to the login screen.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required Future<void> Function() onUnauthorized,
    String? baseUrlOverride,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrlOverride ?? _baseUrlFromEnv,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        // Only 2xx succeeds; everything else surfaces as a DioException.
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token invalid/expired → clear it and flip auth to unauthenticated.
            await _tokenStorage.clear();
            await _onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const String _baseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  late final Dio dio;

  final TokenStorage _tokenStorage;
  final Future<void> Function() _onUnauthorized;
}
