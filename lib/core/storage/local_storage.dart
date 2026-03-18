import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based local storage for artifacts, manifests, and registry files.
/// Uses atomic commit: write to tmp then rename to live.
class LocalStorage {
  static LocalStorage? _instance;
  late Directory _baseDir;
  bool _initialized = false;

  static LocalStorage get instance => _instance ??= LocalStorage._();
  LocalStorage._();

  Future<void> init() async {
    if (_initialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory('${appDir.path}/sdui_cache');
    await _baseDir.create(recursive: true);
    await Directory('${_baseDir.path}/artifacts').create(recursive: true);
    await Directory('${_baseDir.path}/registry').create(recursive: true);
    await Directory('${_baseDir.path}/tmp').create(recursive: true);
    _initialized = true;
  }

  // -- Manifest --

  Future<void> saveManifest(Map<String, dynamic> json) async {
    await _atomicWrite('manifest.json', jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadManifest() async {
    return _readJson('manifest.json');
  }

  // -- Artifacts --

  Future<void> saveArtifact(String screen, Map<String, dynamic> json) async {
    await _atomicWrite('artifacts/$screen.json', jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadArtifact(String screen) async {
    return _readJson('artifacts/$screen.json');
  }

  // -- Registry files --

  Future<void> saveRegistryFile(String type, String name, Map<String, dynamic> json) async {
    await Directory('${_baseDir.path}/registry/$type').create(recursive: true);
    await _atomicWrite('registry/$type/$name.json', jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadRegistryFile(String type, String name) async {
    return _readJson('registry/$type/$name.json');
  }

  // -- Raw file access --

  Future<void> saveRaw(String relativePath, String content) async {
    await _atomicWrite(relativePath, content);
  }

  Future<String?> loadRaw(String relativePath) async {
    final file = File('${_baseDir.path}/$relativePath');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  // -- Atomic write: write to tmp, then rename to live --

  Future<void> _atomicWrite(String relativePath, String content) async {
    await init();
    final tmpFile = File('${_baseDir.path}/tmp/${relativePath.replaceAll('/', '_')}');
    await tmpFile.writeAsString(content);
    final liveFile = File('${_baseDir.path}/$relativePath');
    await liveFile.parent.create(recursive: true);
    await tmpFile.rename(liveFile.path);
  }

  Future<Map<String, dynamic>?> _readJson(String relativePath) async {
    await init();
    final file = File('${_baseDir.path}/$relativePath');
    if (!await file.exists()) return null;
    try {
      final str = await file.readAsString();
      final decoded = jsonDecode(str);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await init();
    if (await _baseDir.exists()) {
      await _baseDir.delete(recursive: true);
      await _baseDir.create(recursive: true);
    }
  }
}
