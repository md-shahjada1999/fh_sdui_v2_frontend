/// Central configuration for SDUI endpoints.
class ScreenConfig {
  static const String manifestUrl =
      'http://192.168.1.64:5000/manifest.json';

  /// Populated at runtime from manifest. Falls back to hardcoded URLs.
  static final Map<String, String> _screenUrls = {
  
  };

  static String? urlForScreen(String screenId) => _screenUrls[screenId];

  /// Called after manifest check to update screen URLs from manifest paths.
  static void updateFromManifest(Map<String, String> screenPaths) {
    _screenUrls.addAll(screenPaths);
  }
}
