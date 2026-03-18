import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:fh_sdui_v2/core/state/sdui_state_controller.dart';

import '../models/sdui_action.dart';
import '../models/sdui_node.dart';
import '../models/sdui_root.dart';
import '../resolver/expression_resolver.dart';
import '../resolver/style_resolver.dart';
import '../resolver/token_resolver.dart';
import '../parser/sdui_parser.dart';
import '../widgets/sdui_widgets.dart';
import '../actions/action_executor.dart';

class LayoutEngine {
  final SduiRoot root;
  final SduiStateController stateController;
  final TokenResolver tokenResolver;
  final StyleResolver styleResolver;
  final ExpressionResolver expressionResolver;
  late ActionExecutor actionExecutor;

  bool _lifecycleDone = false;
  bool _onLoadDone = false;

  Map<String, dynamic>? renderTree;
  String? currentArtifactKey;

  LayoutEngine({
    required this.root,
    required this.stateController,
    required this.tokenResolver,
    required this.styleResolver,
    required this.expressionResolver,
  }) {
    actionExecutor = ActionExecutor(root);
  }

  Widget build() {
    tokenResolver.loadFromRoot(root);
    styleResolver.loadFromRoot(root);
    if (!_lifecycleDone) {
      _lifecycleDone = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _runActionsForEvent('beforeLoad');
      });
    }
    final layoutNode = SduiParser.parseLayout(root);
    final widget = _buildNode(layoutNode);
    if (!_onLoadDone) {
      _onLoadDone = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _runActionsForEvent('onLoad', layoutNode);
        _runActionsForEvent('afterLoad');
      });
    }
    return widget;
  }

  /// Build from a pre-compiled artifact render tree.
  /// Styles are already flat (not class refs), so token/style resolution is skipped.
  Widget buildFromArtifact(Map<String, dynamic> tree) {
    renderTree = tree;
    if (!_lifecycleDone) {
      _lifecycleDone = true;
    }
    final node = SduiNode.fromJson(tree);
    final widget = _buildNode(node);
    if (_lifecycleDone && !_onLoadDone) {
      _onLoadDone = true;
    }
    return widget;
  }

  void _runActionsForEvent(String event, [SduiNode? node]) {
    final list = node?.actions ?? (node == null ? _getLayoutActions() : null);
    if (list == null) return;
    for (final a in list) {
      if (a.event == event) actionExecutor.run(a);
    }
  }

  List<SduiAction> _getLayoutActions() {
    final layoutJson = root.layout;
    final actionsJson = layoutJson['actions'];
    if (actionsJson is! List) return [];
    final list = <SduiAction>[];
    for (final a in actionsJson) {
      if (a is Map<String, dynamic>) list.add(SduiAction.fromJson(a));
    }
    return list;
  }

  Widget _buildNode(SduiNode node) {
    if (node.condition != null && !expressionResolver.resolveBool(node.condition)) {
      return const SizedBox.shrink();
    }
    final visible = node.visible == null || expressionResolver.resolveBool(node.visible);
    if (!visible) return const SizedBox.shrink();

    if (node.repeat != null) {
      return _buildRepeated(node);
    }

    final enabled = node.enabled == null || expressionResolver.resolveBool(node.enabled);

    switch (node.type) {
      case 'screen':
        return SduiScreen(node: node, engine: this, enabled: enabled);
      case 'row':
        return SduiRow(node: node, engine: this, enabled: enabled);
      case 'column':
        return SduiColumn(node: node, engine: this, enabled: enabled);
      case 'container':
        return SduiContainer(node: node, engine: this, enabled: enabled);
      case 'text':
        return SduiText(node: node, engine: this, enabled: enabled);
      case 'rich_text':
        return SduiRichText(node: node, engine: this, enabled: enabled);
      case 'image':
        return SduiImage(node: node, engine: this, enabled: enabled);
      case 'icon':
        return SduiIcon(node: node, engine: this, enabled: enabled);
      case 'button':
        return SduiButton(node: node, engine: this, enabled: enabled);
      case 'input':
        return SduiInput(node: node, engine: this, enabled: enabled);
      case 'spacer':
        return SduiSpacer(node: node, engine: this);
      case 'expanded':
        return SduiExpanded(node: node, engine: this);
      case 'scroll':
        return SduiScroll(node: node, engine: this);
      case 'checkbox':
        return SduiCheckbox(node: node, engine: this, enabled: enabled);
      case 'otp_input':
        return SduiOtpInput(node: node, engine: this, enabled: enabled);
      case 'divider':
        return SduiDivider(node: node, engine: this);
      case 'grid':
        return SduiGrid(node: node, engine: this, enabled: enabled);
      case 'stack':
        return SduiStack(node: node, engine: this, enabled: enabled);
      case 'carousel':
        return SduiCarousel(node: node, engine: this, enabled: enabled);
      case 'bottom_nav':
        return SduiBottomNav(node: node, engine: this);
      case 'component':
        return _buildComponent(node, enabled);
      default:
        return SduiContainer(node: node, engine: this, enabled: enabled);
    }
  }

  Widget _buildRepeated(SduiNode node) {
    final dataKey = node.repeat!.data;
    final itemAlias = node.repeat!.item;
    final list = stateController.getByPath(dataKey);
    if (list is! List || list.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        stateController.setRepeatScope(itemAlias, item);
        final child = _buildNode(node);
        stateController.clearRepeatScope();
        return child;
      },
    );
  }

  Widget _buildComponent(SduiNode node, bool enabled) {
    final name = node.props['name'] as String?;
    if (name == null) return const SizedBox.shrink();
    final comp = SduiParser.parseComponent(root, name);
    if (comp == null) return const SizedBox.shrink();
    return _buildNode(comp);
  }

  List<Widget> buildChildren(List<SduiNode> children) {
    final list = <Widget>[];
    for (final c in children) {
      list.add(_buildNode(c));
    }
    return list;
  }
}
