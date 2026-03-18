import 'sdui_action.dart';

/// UI node schema: type, props, style, children, visible, enabled, condition, repeat, actions.
class SduiNode {
  final String? id;
  final String type;
  final Map<String, dynamic> props;
  final dynamic style;
  final List<SduiNode> children;
  final dynamic visible;
  final dynamic enabled;
  final dynamic condition;
  final RepeatConfig? repeat;
  final List<SduiAction> actions;

  const SduiNode({
    this.id,
    required this.type,
    this.props = const {},
    this.style,
    this.children = const [],
    this.visible,
    this.enabled,
    this.condition,
    this.repeat,
    this.actions = const [],
  });

  factory SduiNode.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'];
    List<SduiNode> childrenList = [];
    if (childrenJson is List) {
      for (final c in childrenJson) {
        if (c is Map<String, dynamic>) {
          childrenList.add(SduiNode.fromJson(c));
        }
      }
    }

    final actionsJson = json['actions'];
    List<SduiAction> actionsList = [];
    if (actionsJson is List) {
      for (final a in actionsJson) {
        if (a is Map<String, dynamic>) {
          actionsList.add(SduiAction.fromJson(a));
        }
      }
    }

    RepeatConfig? repeatConfig;
    final repeatJson = json['repeat'];
    if (repeatJson is Map<String, dynamic>) {
      repeatConfig = RepeatConfig(
        data: repeatJson['data'] as String? ?? '',
        item: repeatJson['item'] as String? ?? 'item',
      );
    }

    return SduiNode(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'container',
      props: json['props'] as Map<String, dynamic>? ?? {},
      style: json['style'],
      children: childrenList,
      visible: json['visible'],
      enabled: json['enabled'],
      condition: json['condition'],
      repeat: repeatConfig,
      actions: actionsList,
    );
  }
}

class RepeatConfig {
  final String data; // key in state for list
  final String item; // alias for each element

  const RepeatConfig({required this.data, required this.item});
}
