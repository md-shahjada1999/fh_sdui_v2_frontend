class SduiArtifact {
  final String artifactVersion;
  final String screen;
  final String artifactKey;
  final Map<String, dynamic> renderTree;

  const SduiArtifact({
    required this.artifactVersion,
    required this.screen,
    required this.artifactKey,
    required this.renderTree,
  });

  factory SduiArtifact.fromJson(Map<String, dynamic> json) {
    return SduiArtifact(
      artifactVersion: json['artifactVersion'] as String? ?? '1.0',
      screen: json['screen'] as String? ?? '',
      artifactKey: json['artifactKey'] as String? ?? '',
      renderTree: json['renderTree'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'artifactVersion': artifactVersion,
    'screen': screen,
    'artifactKey': artifactKey,
    'renderTree': renderTree,
  };

  bool get isValid => artifactKey.isNotEmpty && renderTree.isNotEmpty;
}
