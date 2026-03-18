import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'hash_util.dart';

/// Security layer for SDUI V2: hash verification, secure token storage,
/// and manifest signature verification stub.
class SduiSecurity {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  /// Verify that content matches expected "sha256:..." hash.
  static bool verifyHash(String content, String expectedHash) {
    return HashUtil.verifyHash(content, expectedHash);
  }

  /// Verify manifest signature (stub for RSA/ECDSA verification).
  /// Will be implemented when server starts signing manifests.
  static bool verifyManifestSignature(
    String manifestJson,
    String? signature,
    String? publicKey,
  ) {
    if (signature == null || publicKey == null) return true;
    // TODO: implement RSA/ECDSA signature verification with pointycastle
    return true;
  }

  // -- Secure storage for auth tokens --

  static Future<void> saveToken(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> readToken(String key) async {
    return _secureStorage.read(key: key);
  }

  static Future<void> deleteToken(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> deleteAllTokens() async {
    await _secureStorage.deleteAll();
  }

  static Future<bool> hasToken(String key) async {
    return await _secureStorage.containsKey(key: key);
  }
}
