class SduiPatch {
  final String screen;
  final String baseArtifactKey;
  final String targetArtifactKey;
  final List<PatchOp> ops;

  const SduiPatch({
    required this.screen,
    required this.baseArtifactKey,
    required this.targetArtifactKey,
    required this.ops,
  });

  factory SduiPatch.fromJson(Map<String, dynamic> json) {
    final opsJson = json['ops'] as List? ?? [];
    return SduiPatch(
      screen: json['screen'] as String? ?? '',
      baseArtifactKey: json['baseArtifactKey'] as String? ?? '',
      targetArtifactKey: json['targetArtifactKey'] as String? ?? '',
      ops: opsJson
          .whereType<Map<String, dynamic>>()
          .map((o) => PatchOp.fromJson(o))
          .toList(),
    );
  }
}

class PatchOp {
  final String op;
  final String? id;
  final String? parentId;
  final Map<String, dynamic>? props;
  final dynamic value;

  const PatchOp({
    required this.op,
    this.id,
    this.parentId,
    this.props,
    this.value,
  });

  factory PatchOp.fromJson(Map<String, dynamic> json) {
    return PatchOp(
      op: json['op'] as String? ?? '',
      id: json['id'] as String?,
      parentId: json['parentId'] as String?,
      props: json['props'] as Map<String, dynamic>?,
      value: json['value'],
    );
  }
}
