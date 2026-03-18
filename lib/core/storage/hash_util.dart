import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  /// Compute SHA-256 of content, return `sha256:<base64>`
  static String computeHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    final b64 = base64.encode(digest.bytes);
    return 'sha256:$b64';
  }

  /// Verify that content matches expected hash
  static bool verifyHash(String content, String expectedHash) {
    final computed = computeHash(content);
    return computed == expectedHash;
  }
}
