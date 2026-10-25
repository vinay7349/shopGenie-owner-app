import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving JWT tokens.
///
/// Uses [flutter_secure_storage] which provides encrypted storage
/// on both iOS (Keychain) and Android (Keystore/EncryptedSharedPreferences).
class TokenStorage {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Saves both access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw ArgumentError('Access and refresh tokens must not be empty');
    }
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Reads the access token, or null if not set.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Reads the refresh token, or null if not set.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Checks if both tokens are present.
  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && access.isNotEmpty &&
        refresh != null && refresh.isNotEmpty;
  }

  /// Clears both tokens (used during logout).
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Returns true if access token exists (used for quick auth checks).
  Future<bool> isLoggedIn() async {
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }
}