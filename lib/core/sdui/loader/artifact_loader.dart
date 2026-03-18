import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/services.dart';

import '../../storage/local_storage.dart';
import '../config/screen_config.dart';
import '../models/artifact.dart';

const _tag = 'ArtifactLoader';

/// Loads screen data in dual-mode: pre-compiled artifact (V2) or raw JSON (V1).
/// Cache-first: manifest checker pre-downloads updates, so we read from cache.
/// Fallback chain: 1) local cache, 2) bundled assets, 3) remote API.
class ArtifactLoader {
  final LocalStorage _storage = LocalStorage.instance;
  final dio.Dio _dio = dio.Dio();

  Future<ArtifactLoadResult> loadScreen(String screenId, {String? url}) async {
    await _storage.init();
    dev.log('[$_tag] loadScreen("$screenId")');

    // 1. Try local cache (populated by ManifestChecker on startup)
    final cachedArtifact = await _storage.loadArtifact(screenId);
    if (cachedArtifact != null) {
      dev.log('[$_tag] ✓ "$screenId" loaded from cache');
      return _wrapResult(cachedArtifact);
    }

    // 2. Try bundled assets
    try {
      final jsonStr = await rootBundle.loadString('assets/json/$screenId.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      dev.log('[$_tag] ✓ "$screenId" loaded from bundled assets');
      return _wrapResult(json);
    } catch (_) {
      dev.log('[$_tag] No bundled asset for "$screenId"');
    }

    // 3. Last resort: fetch from remote API directly
    final remoteUrl = url ?? ScreenConfig.urlForScreen(screenId);
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      try {
        dev.log('[$_tag] GET $remoteUrl (fallback) ...');
        final stopwatch = Stopwatch()..start();
        final response = await _dio.get(remoteUrl);
        stopwatch.stop();
        dev.log('[$_tag] ✓ ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms');

        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;

        await _storage.saveArtifact(screenId, data);
        dev.log('[$_tag] Cached "$screenId" to local storage');
        return _wrapResult(data);
      } catch (e) {
        dev.log('[$_tag] ✗ Fallback fetch failed: $e');
      }
    }

    dev.log('[$_tag] ✗ No source found for "$screenId"');
    return ArtifactLoadResult(mode: RenderMode.none);
  }

  ArtifactLoadResult _wrapResult(Map<String, dynamic> data) {
    if (data.containsKey('renderTree')) {
      return ArtifactLoadResult(
        mode: RenderMode.artifact,
        artifact: SduiArtifact.fromJson(data),
      );
    }
    return ArtifactLoadResult(
      mode: RenderMode.rawJson,
      rawJson: data,
    );
  }
}

enum RenderMode { artifact, rawJson, none }

class ArtifactLoadResult {
  final RenderMode mode;
  final SduiArtifact? artifact;
  final Map<String, dynamic>? rawJson;

  const ArtifactLoadResult({
    required this.mode,
    this.artifact,
    this.rawJson,
  });
}
