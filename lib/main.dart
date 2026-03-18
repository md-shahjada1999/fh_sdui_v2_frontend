import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/sdui/config/screen_config.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/manifest_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.instance.init();

  // Manifest check: fetch manifest, diff hashes, download changed screens
  final checker = ManifestChecker();
  final result = await checker.check(ScreenConfig.manifestUrl);

  if (result.manifest != null) {
    // Update screen URL registry from manifest paths
    final screenPaths = <String, String>{};
    for (final e in result.manifest!.screens.entries) {
      if (e.value.path.isNotEmpty) {
        screenPaths[e.key] = e.value.path;
      }
    }
    ScreenConfig.updateFromManifest(screenPaths);
  }

  if (result.hasUpdate) {
    dev.log('[main] Manifest updated screens: ${result.updatedScreens}');
  } else {
    dev.log('[main] No screen updates from manifest');
  }

  runApp(const App());
}
