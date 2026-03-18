/// Central configuration for SDUI endpoints.
class ScreenConfig {
  static const String manifestUrl =
      'http://192.168.1.64:5050/manifest.json';

  /// Base URL prepended to relative API paths (e.g. /api/auth/send-otp).
  /// Update this to point at your real backend.
  static String apiBaseUrl = 'http://192.168.1.64:5050';

  /// Populated at runtime from manifest. Falls back to hardcoded URLs.
  static final Map<String, String> _screenUrls = {};

  static String? urlForScreen(String screenId) => _screenUrls[screenId];

  /// Called after manifest check to update screen URLs from manifest paths.
  static void updateFromManifest(Map<String, String> screenPaths) {
    _screenUrls.addAll(screenPaths);
  }
}
