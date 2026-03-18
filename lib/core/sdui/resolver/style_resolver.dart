import 'package:flutter/material.dart';

import '../models/sdui_root.dart';
import '../models/sdui_style.dart';
import 'token_resolver.dart';

class StyleResolver {
  final TokenResolver _tokenResolver;
  Map<String, dynamic> _classes = {};

  StyleResolver(this._tokenResolver);

  void loadFromRoot(SduiRoot root) {
    _classes = Map<String, dynamic>.from(root.styleClasses);
  }

  SduiResolvedStyle resolve(dynamic styleInput) {
    var resolved = const SduiResolvedStyle();
    if (styleInput == null) return resolved;

    List<dynamic> list = [];
    if (styleInput is List) {
      list = styleInput;
    } else {
      list = [styleInput];
    }

    for (final entry in list) {
      if (entry is String && entry.startsWith('.')) {
        final className = entry.substring(1);
        final classStyle = _classes[className];
        if (classStyle is Map<String, dynamic>) {
          resolved = resolved.merge(_parseStyleMap(classStyle));
        }
      } else if (entry is Map<String, dynamic>) {
        resolved = resolved.merge(_parseStyleMap(entry));
      }
    }
    return resolved;
  }

  SduiResolvedStyle _parseStyleMap(Map<String, dynamic> m) {
    return SduiResolvedStyle(
      backgroundColor: _resolveColor(m['backgroundColor']),
      padding: _resolveEdgeInsets(m['padding']),
      margin: _resolveEdgeInsets(m['margin']),
      borderRadius: _resolveDouble(m['borderRadius']),
      borderColor: _resolveColor(m['borderColor']),
      borderWidth: _resolveDouble(m['borderWidth']),
      fontSize: _resolveDouble(m['fontSize']),
      fontWeight: _resolveFontWeight(m['fontWeight']),
      color: _resolveColor(m['color']),
      width: _resolveDouble(m['width']),
      height: _resolveDouble(m['height']),
      mainAxisAlignment: _resolveMainAxisAlignment(m['mainAxisAlignment']),
      crossAxisAlignment: _resolveCrossAxisAlignment(m['crossAxisAlignment']),
      textAlign: _resolveTextAlign(m['textAlign']),
      elevation: _resolveDouble(m['elevation']),
      opacity: _resolveDouble(m['opacity']),
      flex: _resolveInt(m['flex']),
      gap: _resolveDouble(m['gap']),
      maxLines: _resolveInt(m['maxLines']),
      letterSpacing: _resolveDouble(m['letterSpacing']),
      lineHeight: _resolveDouble(m['lineHeight']),
      textOverflow: _resolveTextOverflow(m['textOverflow']),
      mainAxisSize: _resolveMainAxisSize(m['mainAxisSize']),
      textDecoration: _resolveTextDecoration(m['textDecoration']),
    );
  }

  Color? _resolveColor(dynamic v) {
    final resolved = _tokenResolver.resolve(v);
    if (resolved is! String) return null;
    return TokenResolver.parseColor(resolved);
  }

  double? _resolveDouble(dynamic v) {
    final resolved = _tokenResolver.resolve(v);
    if (resolved is num) return resolved.toDouble();
    if (resolved is String) return double.tryParse(resolved);
    return null;
  }

  int? _resolveInt(dynamic v) {
    final resolved = _tokenResolver.resolve(v);
    if (resolved is int) return resolved;
    if (resolved is num) return resolved.toInt();
    if (resolved is String) return int.tryParse(resolved);
    return null;
  }

  EdgeInsets? _resolveEdgeInsets(dynamic v) {
    if (v == null) return null;
    final resolved = _tokenResolver.resolve(v);
    if (resolved is num) {
      return EdgeInsets.all(resolved.toDouble());
    }
    if (resolved is List && resolved.length == 2) {
      final vertical = _toDouble(resolved[0]);
      final horizontal = _toDouble(resolved[1]);
      return EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
    }
    if (resolved is Map) {
      final top = _toDouble(resolved['top']);
      final right = _toDouble(resolved['right']);
      final bottom = _toDouble(resolved['bottom']);
      final left = _toDouble(resolved['left']);
      return EdgeInsets.fromLTRB(left, top, right, bottom);
    }
    return null;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final resolved = _tokenResolver.resolve(v);
    if (resolved is num) return resolved.toDouble();
    if (resolved is String) return double.tryParse(resolved) ?? 0.0;
    return 0.0;
  }

  FontWeight? _resolveFontWeight(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      switch (v.toLowerCase()) {
        case 'bold':
          return FontWeight.bold;
        case 'w100':
          return FontWeight.w100;
        case 'w200':
          return FontWeight.w200;
        case 'w300':
          return FontWeight.w300;
        case 'normal':
        case 'w400':
          return FontWeight.w400;
        case 'w500':
          return FontWeight.w500;
        case 'w600':
          return FontWeight.w600;
        case 'w700':
          return FontWeight.w700;
        case 'w800':
          return FontWeight.w800;
        case 'w900':
          return FontWeight.w900;
      }
    }
    return null;
  }

  MainAxisAlignment? _resolveMainAxisAlignment(dynamic v) {
    if (v is! String) return null;
    switch (v) {
      case 'start':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
    }
    return null;
  }

  CrossAxisAlignment? _resolveCrossAxisAlignment(dynamic v) {
    if (v is! String) return null;
    switch (v) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
    }
    return null;
  }

  TextAlign? _resolveTextAlign(dynamic v) {
    if (v is! String) return null;
    switch (v) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
    }
    return null;
  }

  TextOverflow? _resolveTextOverflow(dynamic v) {
    if (v is! String) return null;
    switch (v) {
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'clip':
        return TextOverflow.clip;
      case 'fade':
        return TextOverflow.fade;
    }
    return null;
  }

  MainAxisSize? _resolveMainAxisSize(dynamic v) {
    if (v is! String) return null;
    switch (v) {
      case 'max':
        return MainAxisSize.max;
      case 'min':
        return MainAxisSize.min;
    }
    return null;
  }

  TextDecoration? _resolveTextDecoration(dynamic v) {
    if (v is! String) return null;
    switch (v) {
      case 'underline':
        return TextDecoration.underline;
      case 'lineThrough':
        return TextDecoration.lineThrough;
      case 'none':
        return TextDecoration.none;
    }
    return null;
  }
}
