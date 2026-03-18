import 'dart:developer' as dev;

import 'package:dio/dio.dart' as dio;

import '../sdui/config/screen_config.dart';
import '../state/sdui_state_controller.dart';
import '../sdui/models/sdui_api.dart';

const _tag = 'ApiClient';

/// Executes API definitions with {{variable}} templating, store auto-write, and TTL caching.
class ApiClient {
  final dio.Dio _dio = dio.Dio();
  late SduiStateController _state;

  final Map<String, _CachedResponse> _cache = {};

  void setStateController(SduiStateController c) {
    _state = c;
  }

  String _template(String s) {
    if (s.isEmpty) return s;
    final pattern = RegExp(r'\{\{([^}]+)\}\}');
    return s.replaceAllMapped(pattern, (match) {
      final path = match.group(1)?.trim() ?? '';
      final v = _state.getByPath(path);
      return v?.toString() ?? '';
    });
  }

  Map<String, dynamic> _templateMap(Map<String, dynamic>? m) {
    if (m == null) return {};
    final out = <String, dynamic>{};
    for (final e in m.entries) {
      if (e.value is String) {
        out[e.key] = _template(e.value);
      } else if (e.value is Map<String, dynamic>) {
        out[e.key] = _templateMap(e.value);
      } else {
        out[e.key] = e.value;
      }
    }
    return out;
  }

  /// Prepend baseUrl if the URL is a relative path (starts with /).
  String _resolveUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = ScreenConfig.apiBaseUrl;
    if (base.isEmpty) return raw;
    return '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}$raw';
  }

  Future<dio.Response<dynamic>> call(SduiApi apiDef) async {
    final method = apiDef.method;
    final url = _resolveUrl(_template(apiDef.url));
    final cacheKey = '$method:$url';

    if (apiDef.cache != null && apiDef.cache!.ttl > 0) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        dev.log('[$_tag] CACHE HIT $method $url (ttl: ${apiDef.cache!.ttl}s)');
        if (apiDef.store != null) {
          _state.setStateKey(apiDef.store!, cached.data);
        }
        return dio.Response(
          data: cached.data,
          requestOptions: dio.RequestOptions(path: url),
          statusCode: 200,
        );
      }
    }

    final headers = _templateMap(apiDef.headers);
    final query = _templateMap(apiDef.query);
    dynamic body = apiDef.body;
    if (body is Map<String, dynamic>) {
      body = _templateMap(body);
    } else if (body is String) {
      body = _template(body);
    }

    dev.log('[$_tag] $method $url'
        '${query.isNotEmpty ? " query=$query" : ""}'
        '${apiDef.store != null ? " → store: ${apiDef.store}" : ""}');

    final stopwatch = Stopwatch()..start();
    final response = await _dio.request(
      url,
      options: dio.Options(
        method: method,
        headers: headers.isNotEmpty ? headers : null,
      ),
      queryParameters: query.isNotEmpty ? query : null,
      data: body,
    );
    stopwatch.stop();

    dev.log('[$_tag] ✓ ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms');

    if (apiDef.store != null) {
      _state.setStateKey(apiDef.store!, response.data);
      dev.log('[$_tag] Stored response → state["${apiDef.store}"]');
    }

    if (apiDef.cache != null && apiDef.cache!.ttl > 0) {
      _cache[cacheKey] = _CachedResponse(
        data: response.data,
        expiry: DateTime.now().add(Duration(seconds: apiDef.cache!.ttl)),
      );
      dev.log('[$_tag] Cached response (ttl: ${apiDef.cache!.ttl}s)');
    }

    return response;
  }
}

class _CachedResponse {
  final dynamic data;
  final DateTime expiry;

  _CachedResponse({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
