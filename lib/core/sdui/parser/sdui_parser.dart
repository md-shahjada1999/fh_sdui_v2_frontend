import '../models/sdui_node.dart';
import '../models/sdui_root.dart';

/// Parses JSON into SduiRoot and SduiNode trees.
class SduiParser {
  static SduiRoot parseRoot(Map<String, dynamic> json) {
    return SduiRoot.fromJson(json);
  }

  static SduiNode parseLayout(SduiRoot root) {
    return SduiNode.fromJson(root.layout);
  }

  static SduiNode? parseComponent(SduiRoot root, String name) {
    final components = root.components;
    final nodeJson = components[name];
    if (nodeJson is Map<String, dynamic>) {
      return SduiNode.fromJson(nodeJson);
    }
    return null;
  }
}
