import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../state/sdui_state_controller.dart';
import '../models/sdui_action.dart';
import '../models/sdui_api.dart';
import '../models/sdui_root.dart';
import 'device_handler.dart';

/// Executes actions: api, navigate, popup, toast, setState, log,
/// openUrl, analytics, chain, device.
class ActionExecutor {
  final SduiRoot root;
  late SduiStateController _state;
  late ApiClient _apiClient;

  AnalyticsHandler? analyticsHandler;

  ActionExecutor(this.root) {
    _state = Get.find<SduiStateController>();
    _apiClient = ApiClient()..setStateController(_state);
  }

  void run(SduiAction action) {
    switch (action.type) {
      case 'api':
        _runApi(action);
        break;
      case 'navigate':
        _runNavigate(action);
        break;
      case 'popup':
        _runPopup(action);
        break;
      case 'toast':
        _runToast(action);
        break;
      case 'setState':
        _runSetState(action);
        break;
      case 'log':
        _runLog(action);
        break;
      case 'openUrl':
        _runOpenUrl(action);
        break;
      case 'analytics':
        _runAnalytics(action);
        break;
      case 'chain':
        _runChain(action);
        break;
      case 'device':
        _runDevice(action);
        break;
      default:
        _runLog(SduiAction(
          event: '',
          type: 'log',
          props: {'message': 'Unknown action: ${action.type}'},
        ));
    }
  }

  Future<void> _runApi(SduiAction action) async {
    final target = action.target;
    if (target == null) return;
    final apiJson = root.apis[target];
    if (apiJson is! Map<String, dynamic>) return;
    final apiDef = SduiApi.fromJson(apiJson);
    try {
      final response = await _apiClient.call(apiDef);
      final data = response.data;
      final stateKey = apiDef.store ?? action.props?['stateKey'] as String? ?? target;
      _state.setStateKey(stateKey, data);
      if (action.onSuccess != null) run(action.onSuccess!);
    } catch (e) {
      if (action.onFail != null) {
        run(action.onFail!);
      } else {
        Get.snackbar('Error', e.toString());
      }
    }
  }

  void _runNavigate(SduiAction action) {
    final route = action.props?['route'] as String? ?? action.target ?? '/';
    final args = action.props?['arguments'];
    final replace = action.props?['replace'] == true;
    if (replace) {
      if (args != null) {
        Get.offAllNamed(route, arguments: args);
      } else {
        Get.offAllNamed(route);
      }
    } else {
      if (args != null) {
        Get.toNamed(route, arguments: args);
      } else {
        Get.toNamed(route);
      }
    }
  }

  void _runPopup(SduiAction action) {
    final title = action.props?['title'] as String? ?? 'Info';
    final message = action.props?['message'] as String? ?? '';
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _runToast(SduiAction action) {
    final message = action.props?['message'] as String? ?? action.target ?? '';
    Get.snackbar(
      action.props?['title'] as String? ?? 'Notice',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _runSetState(SduiAction action) {
    final key = action.props?['key'] as String?;
    final value = action.props?['value'];
    if (key != null) {
      _state.setByPath(key, value);
    }
  }

  void _runLog(SduiAction action) {
    final message = action.props?['message'] ?? action.type;
    // ignore: avoid_print
    print('[SDUI] $message');
  }

  Future<void> _runOpenUrl(SduiAction action) async {
    final urlStr = action.props?['url'] as String? ?? action.target ?? '';
    if (urlStr.isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (action.onSuccess != null) run(action.onSuccess!);
    } catch (e) {
      if (action.onFail != null) {
        run(action.onFail!);
      }
    }
  }

  void _runAnalytics(SduiAction action) {
    final eventName = action.props?['event'] as String? ?? '';
    final params = action.props?['params'] as Map<String, dynamic>? ?? {};

    if (analyticsHandler != null) {
      analyticsHandler!.logEvent(eventName, params);
    } else {
      // ignore: avoid_print
      print('[SDUI Analytics] $eventName ${params.isNotEmpty ? params : ""}');
    }
    if (action.onSuccess != null) run(action.onSuccess!);
  }

  Future<void> _runChain(SduiAction action) async {
    final actionsJson = action.props?['actions'] as List?;
    if (actionsJson == null || actionsJson.isEmpty) return;

    for (final actionJson in actionsJson) {
      if (actionJson is Map<String, dynamic>) {
        final chainedAction = SduiAction.fromJson(actionJson);
        run(chainedAction);
      }
    }
    if (action.onSuccess != null) run(action.onSuccess!);
  }

  Future<void> _runDevice(SduiAction action) async {
    final target = action.target ?? action.props?['target'] as String? ?? '';
    if (target.isEmpty) return;

    try {
      final result = await DeviceHandler.handle(target, action.props);
      if (result.containsKey('error')) {
        if (action.onFail != null) {
          _state.setStateKey('result', result);
          run(action.onFail!);
        }
      } else {
        _state.setStateKey('result', result);
        if (action.onSuccess != null) run(action.onSuccess!);
      }
    } catch (e) {
      if (action.onFail != null) {
        run(action.onFail!);
      }
    }
  }
}

/// Interface for pluggable analytics (Firebase, Mixpanel, etc.)
abstract class AnalyticsHandler {
  void logEvent(String eventName, Map<String, dynamic> params);
}
