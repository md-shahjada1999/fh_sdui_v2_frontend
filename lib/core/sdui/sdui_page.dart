import 'package:flutter/material.dart';

import 'loader/artifact_loader.dart';
import 'sdui_screen.dart';

/// Reusable SDUI page with V2 startup flow:
/// 1. Load local artifact (if exists) and render immediately
/// 2. In background: check manifest for updates (no-op if no server)
/// 3. If updated: re-render from new artifact
/// 4. If no local cache: show loading, fetch, then render
class SduiPage extends StatefulWidget {
  final String screenId;

  const SduiPage({super.key, required this.screenId});

  @override
  State<SduiPage> createState() => _SduiPageState();
}

class _SduiPageState extends State<SduiPage> {
  final ArtifactLoader _loader = ArtifactLoader();
  ArtifactLoadResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _loader.loadScreen(widget.screenId);
    if (mounted) {
      setState(() {
        _result = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final result = _result!;
    switch (result.mode) {
      case RenderMode.artifact:
        return SduiScreenWidget(artifact: result.artifact);
      case RenderMode.rawJson:
        return SduiScreenWidget(json: result.rawJson);
      case RenderMode.none:
        return Scaffold(
          body: Center(
            child: Text('No content for "${widget.screenId}"'),
          ),
        );
    }
  }
}
