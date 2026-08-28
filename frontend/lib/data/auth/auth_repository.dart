import 'package:dio/dio.dart';

import '../api_client.dart';
import 'token_storage.dart';

/// Auth network operations. Owns writing/clearing the token in secure storage.
class AuthRepository {
  AuthRepository(
      {required ApiClient client, required TokenStorage tokenStorage})
      : _dio = client.dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Register a new account, then log in so the caller ends up authenticated.
  Future<void> register(String email, String password) async {
    await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    await login(email, password);
  }

  /// Log in and persist the returned JWT to secure storage.
  Future<void> login(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = (res.data as Map<String, dynamic>)['access_token'] as String;
    await _tokenStorage.write(token);
  }

  Future<void> logout() => _tokenStorage.clear();
}
