import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over [FlutterSecureStorage] for the JWT access token.
///
/// The token is a credential — it is kept in secure storage, never in
/// SharedPreferences (which is plain-text on disk / inspectable on web).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kTokenKey = 'finquest_access_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _kTokenKey);

  Future<void> write(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _kTokenKey);
}
