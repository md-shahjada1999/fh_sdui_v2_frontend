import 'package:fh_sdui_v2/core/state/sdui_state_controller.dart';

/// Replaces {{variable}} with values from GetX state and evaluates expressions.
/// Supports: &&, ||, !, .length, .isEmpty, .isNotEmpty, >=, <=, ==, !=, >, <
class ExpressionResolver {
  final SduiStateController _stateController;

  ExpressionResolver(this._stateController);

  /// Resolve {{path}} in string. Multiple placeholders supported.
  String resolveString(String? value) {
    if (value == null) return '';
    final pattern = RegExp(r'\{\{([^}]+)\}\}');
    return value.replaceAllMapped(pattern, (match) {
      final path = match.group(1)?.trim() ?? '';
      final v = _stateController.getByPath(path);
      return v?.toString() ?? '';
    });
  }

  /// Evaluate expression to bool (for visible, enabled, condition).
  /// Supports simple values and complex expressions:
  ///   "{{form.terms}}"
  ///   "{{form.terms && form.mobile.length >= 10}}"
  ///   "{{!state.loading}}"
  ///   "{{state.count > 0 || form.override}}"
  bool resolveBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) {
      final trimmed = value.trim();

      // Single expression: {{expr}}
      final singleMatch = RegExp(r'^\{\{(.+)\}\}$').firstMatch(trimmed);
      if (singleMatch != null) {
        final expr = singleMatch.group(1)!.trim();
        return _evaluateExpr(expr);
      }

      // Plain string fallback
      if (trimmed == 'true' || trimmed == '1') return true;
      if (trimmed == 'false' || trimmed == '0' || trimmed.isEmpty) return false;

      final v = _stateController.getByPath(trimmed);
      if (v is bool) return v;
      return v != null && v != '';
    }
    return false;
  }

  /// Evaluate a raw expression string (without {{ }}).
  bool _evaluateExpr(String expr) {
    expr = expr.trim();

    // Handle || (lowest precedence) — split on || not inside nested expressions
    final orParts = _splitOutsideParens(expr, '||');
    if (orParts.length > 1) {
      for (final part in orParts) {
        if (_evaluateExpr(part)) return true;
      }
      return false;
    }

    // Handle && 
    final andParts = _splitOutsideParens(expr, '&&');
    if (andParts.length > 1) {
      for (final part in andParts) {
        if (!_evaluateExpr(part)) return false;
      }
      return true;
    }

    // Handle ! (not)
    if (expr.startsWith('!')) {
      return !_evaluateExpr(expr.substring(1));
    }

    // Handle parentheses
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _evaluateExpr(expr.substring(1, expr.length - 1));
    }

    // Handle comparison operators: >=, <=, !=, ==, >, <
    for (final op in ['>=', '<=', '!=', '==', '>', '<']) {
      final idx = expr.indexOf(op);
      if (idx > 0) {
        final left = _resolveValue(expr.substring(0, idx).trim());
        final right = _resolveValue(expr.substring(idx + op.length).trim());
        return _compare(left, right, op);
      }
    }

    // Single value — resolve and check truthiness
    final v = _resolveValue(expr);
    return _isTruthy(v);
  }

  /// Resolve a value token: could be a path (form.mobile.length), a number, or a string literal.
  dynamic _resolveValue(String token) {
    token = token.trim();

    // Numeric literal
    final asNum = num.tryParse(token);
    if (asNum != null) return asNum;

    // Boolean literal
    if (token == 'true') return true;
    if (token == 'false') return false;

    // String literal (quoted)
    if ((token.startsWith("'") && token.endsWith("'")) ||
        (token.startsWith('"') && token.endsWith('"'))) {
      return token.substring(1, token.length - 1);
    }

    // Handle .length, .isEmpty, .isNotEmpty suffixes
    if (token.endsWith('.length')) {
      final path = token.substring(0, token.length - '.length'.length);
      final v = _stateController.getByPath(path);
      if (v is String) return v.length;
      if (v is List) return v.length;
      return 0;
    }
    if (token.endsWith('.isEmpty')) {
      final path = token.substring(0, token.length - '.isEmpty'.length);
      final v = _stateController.getByPath(path);
      if (v is String) return v.isEmpty;
      if (v is List) return v.isEmpty;
      return v == null;
    }
    if (token.endsWith('.isNotEmpty')) {
      final path = token.substring(0, token.length - '.isNotEmpty'.length);
      final v = _stateController.getByPath(path);
      if (v is String) return v.isNotEmpty;
      if (v is List) return v.isNotEmpty;
      return v != null;
    }

    // State path lookup
    return _stateController.getByPath(token);
  }

  bool _compare(dynamic left, dynamic right, String op) {
    // Numeric comparison
    final lNum = _toNum(left);
    final rNum = _toNum(right);
    if (lNum != null && rNum != null) {
      switch (op) {
        case '>=': return lNum >= rNum;
        case '<=': return lNum <= rNum;
        case '>':  return lNum > rNum;
        case '<':  return lNum < rNum;
        case '==': return lNum == rNum;
        case '!=': return lNum != rNum;
      }
    }

    // String/generic equality
    switch (op) {
      case '==': return left?.toString() == right?.toString();
      case '!=': return left?.toString() != right?.toString();
    }

    return false;
  }

  num? _toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  bool _isTruthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty && v != 'false' && v != '0';
    if (v is List) return v.isNotEmpty;
    return true;
  }

  /// Split expression by operator, respecting parentheses depth.
  List<String> _splitOutsideParens(String expr, String op) {
    final parts = <String>[];
    int depth = 0;
    int start = 0;
    for (int i = 0; i < expr.length; i++) {
      if (expr[i] == '(') depth++;
      if (expr[i] == ')') depth--;
      if (depth == 0 && i + op.length <= expr.length && expr.substring(i, i + op.length) == op) {
        parts.add(expr.substring(start, i));
        start = i + op.length;
        i += op.length - 1;
      }
    }
    parts.add(expr.substring(start));
    return parts;
  }

  /// Get raw value by path (for repeat data list).
  dynamic resolvePath(String path) {
    return _stateController.getByPath(path);
  }

  /// Resolve any value: if string with {{}}, resolve; else return as-is.
  dynamic resolve(dynamic value) {
    if (value is String) return resolveString(value);
    return value;
  }
}
