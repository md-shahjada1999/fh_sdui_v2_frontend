import '../models/patch.dart';

/// Applies incremental patch operations to a render tree.
/// Operates on a mutable node tree keyed by node `id`.
class PatchEngine {
  /// Apply a patch to the current render tree. Returns the mutated tree.
  /// Throws [PatchException] on base mismatch or missing target node.
  Map<String, dynamic> applyPatch(
    SduiPatch patch,
    Map<String, dynamic> currentTree,
    String currentArtifactKey,
  ) {
    if (patch.baseArtifactKey != currentArtifactKey) {
      throw PatchException(
        'Base artifact key mismatch: '
        'expected ${patch.baseArtifactKey}, got $currentArtifactKey',
      );
    }

    final index = _buildNodeIndex(currentTree);

    for (final op in patch.ops) {
      switch (op.op) {
        case 'remove':
          _applyRemove(op, currentTree, index);
          break;
        case 'append':
          _applyAppend(op, index);
          break;
        case 'update':
          _applyUpdate(op, index);
          break;
        case 'replace':
          _applyReplace(op, currentTree, index);
          break;
        default:
          throw PatchException('Unknown op: ${op.op}');
      }
    }

    return currentTree;
  }

  /// Build O(1) lookup index: node id -> node map reference
  Map<String, Map<String, dynamic>> _buildNodeIndex(
    Map<String, dynamic> tree,
  ) {
    final index = <String, Map<String, dynamic>>{};
    _indexNode(tree, index);
    return index;
  }

  void _indexNode(
    Map<String, dynamic> node,
    Map<String, Map<String, dynamic>> index,
  ) {
    final id = node['id'] as String?;
    if (id != null && id.isNotEmpty) {
      index[id] = node;
    }
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          _indexNode(child, index);
        }
      }
    }
  }

  void _applyRemove(
    PatchOp op,
    Map<String, dynamic> tree,
    Map<String, Map<String, dynamic>> index,
  ) {
    final targetId = op.id;
    if (targetId == null) throw PatchException('remove op requires id');
    _removeNodeById(tree, targetId);
    index.remove(targetId);
  }

  bool _removeNodeById(Map<String, dynamic> parent, String targetId) {
    final children = parent['children'];
    if (children is! List) return false;
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is Map<String, dynamic> && child['id'] == targetId) {
        children.removeAt(i);
        return true;
      }
    }
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        if (_removeNodeById(child, targetId)) return true;
      }
    }
    return false;
  }

  void _applyAppend(
    PatchOp op,
    Map<String, Map<String, dynamic>> index,
  ) {
    final parentId = op.parentId;
    if (parentId == null) throw PatchException('append op requires parentId');
    final parent = index[parentId];
    if (parent == null) throw PatchException('Parent node "$parentId" not found');

    final value = op.value;
    if (value == null) throw PatchException('append op requires value');

    final children = parent['children'] ??= <dynamic>[];
    if (children is List) {
      final newNode = value is Map<String, dynamic> ? value : <String, dynamic>{};
      children.add(newNode);
      _indexNode(newNode, index);
    }
  }

  void _applyUpdate(
    PatchOp op,
    Map<String, Map<String, dynamic>> index,
  ) {
    final targetId = op.id;
    if (targetId == null) throw PatchException('update op requires id');
    final node = index[targetId];
    if (node == null) throw PatchException('Node "$targetId" not found');

    if (op.props != null) {
      final existingProps = node['props'] as Map<String, dynamic>? ?? {};
      existingProps.addAll(op.props!);
      node['props'] = existingProps;
    }

    final value = op.value;
    if (value is Map<String, dynamic>) {
      if (value.containsKey('style')) {
        node['style'] = value['style'];
      }
      if (value.containsKey('props')) {
        final existingProps = node['props'] as Map<String, dynamic>? ?? {};
        existingProps.addAll(value['props'] as Map<String, dynamic>);
        node['props'] = existingProps;
      }
      if (value.containsKey('visible')) {
        node['visible'] = value['visible'];
      }
      if (value.containsKey('enabled')) {
        node['enabled'] = value['enabled'];
      }
    }
  }

  void _applyReplace(
    PatchOp op,
    Map<String, dynamic> tree,
    Map<String, Map<String, dynamic>> index,
  ) {
    final targetId = op.id;
    if (targetId == null) throw PatchException('replace op requires id');
    final value = op.value;
    if (value is! Map<String, dynamic>) {
      throw PatchException('replace op requires a Map value');
    }

    _replaceNodeById(tree, targetId, value);

    index.remove(targetId);
    _indexNode(value, index);
  }

  bool _replaceNodeById(
    Map<String, dynamic> parent,
    String targetId,
    Map<String, dynamic> replacement,
  ) {
    final children = parent['children'];
    if (children is! List) return false;
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is Map<String, dynamic> && child['id'] == targetId) {
        children[i] = replacement;
        return true;
      }
    }
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        if (_replaceNodeById(child, targetId, replacement)) return true;
      }
    }
    return false;
  }
}

class PatchException implements Exception {
  final String message;
  PatchException(this.message);

  @override
  String toString() => 'PatchException: $message';
}
