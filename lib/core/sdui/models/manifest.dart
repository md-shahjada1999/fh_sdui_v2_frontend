class SduiManifest {
  final String version;
  final Map<String, ManifestEntry> registry;
  final Map<String, ManifestEntry> screens;
  final Map<String, ManifestEntry> apis;

  const SduiManifest({
    required this.version,
    this.registry = const {},
    this.screens = const {},
    this.apis = const {},
  });

  factory SduiManifest.fromJson(Map<String, dynamic> json) {
    return SduiManifest(
      version: json['version'] as String? ?? '0.0.0',
      registry: _parseEntries(json['registry']),
      screens: _parseEntries(json['screens']),
      apis: _parseEntries(json['apis']),
    );
  }

  static Map<String, ManifestEntry> _parseEntries(dynamic data) {
    if (data is! Map<String, dynamic>) return {};
    final out = <String, ManifestEntry>{};
    for (final e in data.entries) {
      if (e.value is Map<String, dynamic>) {
        out[e.key] = ManifestEntry.fromJson(e.value as Map<String, dynamic>);
      }
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'registry': registry.map((k, v) => MapEntry(k, v.toJson())),
    'screens': screens.map((k, v) => MapEntry(k, v.toJson())),
    'apis': apis.map((k, v) => MapEntry(k, v.toJson())),
  };
}

class ManifestEntry {
  final String path;
  final String hash;
  final int? size;

  const ManifestEntry({
    required this.path,
    required this.hash,
    this.size,
  });

  factory ManifestEntry.fromJson(Map<String, dynamic> json) {
    return ManifestEntry(
      path: json['path'] as String? ?? '',
      hash: json['hash'] as String? ?? '',
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'hash': hash,
    if (size != null) 'size': size,
  };
}
