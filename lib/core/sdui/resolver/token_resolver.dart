import 'package:flutter/material.dart' show Color;

import '../models/sdui_root.dart';

/// Flattens tokens to a map with dotted keys (e.g. colors.primary).
Map<String, dynamic> _flattenTokens(Map<String, dynamic> map, [String prefix = '']) {
  final out = <String, dynamic>{};
  for (final e in map.entries) {
    final key = prefix.isEmpty ? e.key : '$prefix.${e.key}';
    if (e.value is Map<String, dynamic>) {
      out.addAll(_flattenTokens(e.value as Map<String, dynamic>, key));
    } else {
      out[key] = e.value;
    }
  }
  return out;
}

/// Resolves #tokens.path in values (e.g. #tokens.colors.primary). No leading $.
class TokenResolver {
  late Map<String, dynamic> _flat;

  void loadFromRoot(SduiRoot root) {
    _flat = _flattenTokens(root.tokens);
  }

  void loadFromMap(Map<String, dynamic> tokens) {
    _flat = _flattenTokens(tokens);
  }

  /// Resolves #tokens.path in string values. Accepts dynamic so style values (int, Map, etc.) pass through.
  dynamic resolve(dynamic value) {
    if (value == null) return value;
    if (value is! String) return value;
    final s = value.trim();
    if (s.startsWith('#tokens.') && !s.startsWith(r'$')) {
      final path = s.substring('#tokens.'.length);
      return _flat[path] ?? value;
    }
    return value;
  }

  /// Resolve and convert to Color if hex string.
  Color? resolveColor(dynamic value) {
    final v = resolve(value);
    if (v is! String) return null;
      return parseColor(v);
  }

  static Color? parseColor(String s) {
    s = s.trim();
    if (s.startsWith('#')) {
      final hex = s.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }

  double? resolveDouble(dynamic value) {
    final v = resolve(value);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
