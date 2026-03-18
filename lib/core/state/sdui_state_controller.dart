import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// GetX state for SDUI: variables, form data, API response keys.
/// Namespaces: state.*, form.*, plus API keys (e.g. users, modules).
class SduiStateController extends GetxController {
  final RxMap<String, dynamic> _state = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _form = <String, dynamic>{}.obs;

  /// Repeat scope: when inside a repeat, item alias -> current item
  final RxMap<String, dynamic> _repeatScope = <String, dynamic>{}.obs;

  bool _updateScheduled = false;

  Map<String, dynamic> get state => _state;
  Map<String, dynamic> get form => _form;
  Map<String, dynamic> get repeatScope => _repeatScope;

  /// Schedule update after current frame to avoid setState/markNeedsBuild during build.
  void _scheduleUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      update();
    });
  }

  /// Get value by path e.g. "state.loggedIn", "form.email", "user.name"
  dynamic getByPath(String path) {
    final parts = path.split('.');
    if (parts.isEmpty) return null;
    Map<String, dynamic>? current;
    if (parts[0] == 'state') {
      current = _state;
    } else if (parts[0] == 'form') {
      current = _form;
    } else if (_repeatScope.containsKey(parts[0])) {
      final item = _repeatScope[parts[0]];
      if (parts.length == 1) return item;
      return _getFromDynamic(item, parts.sublist(1));
    } else {
      current = _state;
    }
    final keys = parts[0] == 'state' || parts[0] == 'form'
        ? parts.sublist(1)
        : parts;
    return _getFromMap(current, keys);
  }

  dynamic _getFromMap(Map<String, dynamic>? m, List<String> keys) {
    if (m == null || keys.isEmpty) return null;
    dynamic current = m;
    for (final k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }
    return current;
  }

  dynamic _getFromDynamic(dynamic value, List<String> keys) {
    if (keys.isEmpty) return value;
    if (value is Map && value.containsKey(keys[0])) {
      return _getFromDynamic(value[keys[0]], keys.sublist(1));
    }
    return null;
  }

  void setByPath(String path, dynamic value) {
    final parts = path.split('.');
    if (parts.isEmpty) return;
    if (parts[0] == 'state') {
      if (parts.length == 1) return;
      _setNested(_state, parts.sublist(1), value);
    } else if (parts[0] == 'form') {
      if (parts.length == 1) return;
      _setNested(_form, parts.sublist(1), value);
    } else {
      _setNested(_state, parts, value);
    }
  }

  void _setNested(Map<String, dynamic> map, List<String> keys, dynamic value) {
    if (keys.length == 1) {
      map[keys[0]] = value;
      _scheduleUpdate();
      return;
    }
    final key = keys[0];
    if (!map.containsKey(key) || map[key] is! Map) {
      map[key] = <String, dynamic>{};
    }
    _setNested(map[key] as Map<String, dynamic>, keys.sublist(1), value);
  }

  void setFormField(String name, dynamic value) {
    _form[name] = value;
    _scheduleUpdate();
  }

  void setStateKey(String key, dynamic value) {
    _state[key] = value;
    _scheduleUpdate();
  }

  void setRepeatScope(String alias, dynamic item) {
    _repeatScope[alias] = item;
  }

  void clearRepeatScope() {
    _repeatScope.clear();
  }

  void clearForm() {
    _form.clear();
  }

  void clearAll() {
    _state.clear();
    _form.clear();
    _repeatScope.clear();
  }

  /// Initialize state for a screen (e.g. modules list for dashboard)
  void initScreenState(Map<String, dynamic> initial) {
    for (final e in initial.entries) {
      setByPath(e.key, e.value);
    }
  }
}
