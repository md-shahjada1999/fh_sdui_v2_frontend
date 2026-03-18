import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart' as dio;

import '../sdui/models/manifest.dart';
import 'local_storage.dart';

const _tag = 'ManifestChecker';

/// Checks server manifest against local, downloads changed screens, atomic commit.
class ManifestChecker {
  final LocalStorage _storage = LocalStorage.instance;
  final dio.Dio _dio = dio.Dio();

  /// Full startup check:
  /// 1. Load local manifest
  /// 2. Fetch server manifest
  /// 3. Diff hashes
  /// 4. Download changed screens and cache them
  /// Returns the result with manifest and list of updated screens.
  Future<ManifestCheckResult> check(String manifestUrl) async {
    await _storage.init();

    final localManifestJson = await _storage.loadManifest();
    final localManifest = localManifestJson != null
        ? SduiManifest.fromJson(localManifestJson)
        : null;
    dev.log('[$_tag] Local manifest: ${localManifest != null ? "v${localManifest.version}" : "none"}');

    try {
      dev.log('[$_tag] GET $manifestUrl ...');
      final stopwatch = Stopwatch()..start();
      final response = await _dio.get(manifestUrl);
      stopwatch.stop();
      dev.log('[$_tag] ✓ ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 304 || response.data == null) {
        dev.log('[$_tag] 304 Not Modified — no update');
        return ManifestCheckResult(
          manifest: localManifest,
          hasUpdate: false,
          updatedScreens: [],
        );
      }

      final serverManifest = SduiManifest.fromJson(
        response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data.toString()),
      );
      dev.log('[$_tag] Server manifest: v${serverManifest.version} '
          '(${serverManifest.screens.length} screens)');

      final changedScreens = _diffEntries(
        localManifest?.screens ?? {},
        serverManifest.screens,
      );

      if (changedScreens.isEmpty) {
        dev.log('[$_tag] All hashes match — no downloads needed');
        await _storage.saveManifest(serverManifest.toJson());
        return ManifestCheckResult(
          manifest: serverManifest,
          hasUpdate: false,
          updatedScreens: [],
        );
      }

      dev.log('[$_tag] Changed screens: $changedScreens');
      final downloadedScreens = <String>[];

      for (final key in changedScreens) {
        final entry = serverManifest.screens[key];
        if (entry == null) continue;
        final success = await _downloadScreen(key, entry.path);
        if (success) downloadedScreens.add(key);
      }

      await _storage.saveManifest(serverManifest.toJson());
      dev.log('[$_tag] Manifest saved. Downloaded ${downloadedScreens.length}/${changedScreens.length} screens');

      return ManifestCheckResult(
        manifest: serverManifest,
        hasUpdate: downloadedScreens.isNotEmpty,
        updatedScreens: downloadedScreens,
      );
    } catch (e) {
      dev.log('[$_tag] ✗ Manifest check failed: $e — using local');
      return ManifestCheckResult(
        manifest: localManifest,
        hasUpdate: false,
        updatedScreens: [],
      );
    }
  }

  /// Returns list of keys whose hashes differ between local and server.
  List<String> _diffEntries(
    Map<String, ManifestEntry> local,
    Map<String, ManifestEntry> server,
  ) {
    final changed = <String>[];
    for (final key in server.keys) {
      final localEntry = local[key];
      if (localEntry == null || localEntry.hash != server[key]!.hash) {
        changed.add(key);
      }
    }
    return changed;
  }

  /// Download a screen JSON from its path (absolute URL) and save as artifact.
  Future<bool> _downloadScreen(String screenId, String url) async {
    try {
      dev.log('[$_tag]   GET $screenId → $url');
      final stopwatch = Stopwatch()..start();
      final response = await _dio.get(url);
      stopwatch.stop();

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(response.data.toString()) as Map<String, dynamic>;

      await _storage.saveArtifact(screenId, data);
      dev.log('[$_tag]   ✓ $screenId cached (${stopwatch.elapsedMilliseconds}ms)');
      return true;
    } catch (e) {
      dev.log('[$_tag]   ✗ $screenId download failed: $e');
      return false;
    }
  }
}

class ManifestCheckResult {
  final SduiManifest? manifest;
  final bool hasUpdate;
  final List<String> updatedScreens;

  const ManifestCheckResult({
    this.manifest,
    required this.hasUpdate,
    required this.updatedScreens,
  });
}
