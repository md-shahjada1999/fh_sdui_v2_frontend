class SduiApi {
  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? query;
  final dynamic body;
  final String? store;
  final String? namespace;
  final ApiCacheConfig? cache;

  const SduiApi({
    required this.method,
    required this.url,
    this.headers,
    this.query,
    this.body,
    this.store,
    this.namespace,
    this.cache,
  });

  factory SduiApi.fromJson(Map<String, dynamic> json) {
    ApiCacheConfig? cacheConfig;
    final cacheJson = json['cache'];
    if (cacheJson is Map<String, dynamic>) {
      cacheConfig = ApiCacheConfig(
        ttl: (cacheJson['ttl'] as num?)?.toInt() ?? 0,
      );
    }

    return SduiApi(
      method: (json['method'] as String? ?? 'GET').toUpperCase(),
      url: json['url'] as String? ?? '',
      headers: json['headers'] as Map<String, dynamic>?,
      query: json['query'] as Map<String, dynamic>?,
      body: json['body'],
      store: json['store'] as String?,
      namespace: json['namespace'] as String?,
      cache: cacheConfig,
    );
  }
}

class ApiCacheConfig {
  final int ttl;

  const ApiCacheConfig({required this.ttl});
}
