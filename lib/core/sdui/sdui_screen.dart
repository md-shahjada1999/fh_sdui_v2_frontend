import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fh_sdui_v2/core/state/sdui_state_controller.dart';
import 'package:fh_sdui_v2/core/sdui/engine/layout_engine.dart';
import 'package:fh_sdui_v2/core/sdui/parser/sdui_parser.dart';
import 'package:fh_sdui_v2/core/sdui/resolver/expression_resolver.dart';
import 'package:fh_sdui_v2/core/sdui/resolver/style_resolver.dart';
import 'package:fh_sdui_v2/core/sdui/resolver/token_resolver.dart';
import 'package:fh_sdui_v2/core/sdui/models/artifact.dart';

/// Single SDUI screen: supports both raw JSON (V1) and pre-compiled artifact (V2).
class SduiScreenWidget extends StatefulWidget {
  final Map<String, dynamic>? json;
  final SduiArtifact? artifact;

  const SduiScreenWidget({super.key, this.json, this.artifact})
      : assert(json != null || artifact != null);

  @override
  State<SduiScreenWidget> createState() => _SduiScreenWidgetState();
}

class _SduiScreenWidgetState extends State<SduiScreenWidget> {
  late final LayoutEngine _engine;
  late final bool _isArtifactMode;

  @override
  void initState() {
    super.initState();
    final stateController = Get.find<SduiStateController>();

    if (widget.artifact != null && widget.artifact!.isValid) {
      _isArtifactMode = true;
      final root = SduiParser.parseRoot({});
      final tokenResolver = TokenResolver();
      final styleResolver = StyleResolver(tokenResolver);
      final expressionResolver = ExpressionResolver(stateController);
      _engine = LayoutEngine(
        root: root,
        stateController: stateController,
        tokenResolver: tokenResolver,
        styleResolver: styleResolver,
        expressionResolver: expressionResolver,
      );
      _engine.currentArtifactKey = widget.artifact!.artifactKey;
      _engine.renderTree = widget.artifact!.renderTree;
    } else {
      _isArtifactMode = false;
      final root = SduiParser.parseRoot(widget.json!);
      final tokenResolver = TokenResolver()..loadFromRoot(root);
      final styleResolver = StyleResolver(tokenResolver)..loadFromRoot(root);
      final expressionResolver = ExpressionResolver(stateController);
      _engine = LayoutEngine(
        root: root,
        stateController: stateController,
        tokenResolver: tokenResolver,
        styleResolver: styleResolver,
        expressionResolver: expressionResolver,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SduiStateController>(
      builder: (_) {
        if (_isArtifactMode) {
          return _engine.buildFromArtifact(_engine.renderTree!);
        }
        return _engine.build();
      },
    );
  }
}
