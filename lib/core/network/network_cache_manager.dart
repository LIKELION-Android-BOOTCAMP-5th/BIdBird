import 'dart:collection';

/// Repository 레벨 메모리 캐시 (TTL 기반)
/// 
/// LRU 정책으로 최대 50개 항목 저장
/// 각 항목에 TTL 설정 가능 (기본 5분)
class NetworkCacheManager {
  static final NetworkCacheManager _instance = NetworkCacheManager._internal();
  factory NetworkCacheManager() => _instance;
  NetworkCacheManager._internal();

  static const int _maxCacheSize = 50;
  static const Duration _defaultTTL = Duration(minutes: 5);

  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();

  /// 캐시 키 생성
  String _generateKey({
    required String endpoint,
    Map<String, dynamic>? params,
  }) {
    final buffer = StringBuffer();
    buffer.write(endpoint);

    if (params != null && params.isNotEmpty) {
      final sortedKeys = params.keys.toList()..sort();
      buffer.write('?');
      for (var i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        buffer.write('$key=${params[key]}');
        if (i < sortedKeys.length - 1) {
          buffer.write('&');
        }
      }
    }

    return buffer.toString();
  }

  /// 캐시에서 데이터 가져오기
  /// 
  /// TTL이 만료되었거나 데이터가 없으면 null 반환
  T? get<T>({
    required String endpoint,
    Map<String, dynamic>? params,
  }) {
    final key = _generateKey(endpoint: endpoint, params: params);
    final entry = _cache[key];

    if (entry == null) {
      print('[NetworkCache] Cache miss: $endpoint');
      return null;
    }

    // TTL 확인
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      print('[NetworkCache] Cache expired: $endpoint');
      return null;
    }

    // LRU: 접근 시 맨 뒤로 이동
    _cache.remove(key);
    _cache[key] = entry;

    print('[NetworkCache] Cache hit: $endpoint');
    return entry.data as T;
  }

  /// 캐시에 데이터 저장
  void set<T>({
    required String endpoint,
    Map<String, dynamic>? params,
    required T data,
    Duration? ttl,
  }) {
    final key = _generateKey(endpoint: endpoint, params: params);
    final expiresAt = DateTime.now().add(ttl ?? _defaultTTL);

    // LRU: 최대 크기 초과 시 가장 오래된 항목 제거
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      print('[NetworkCache] Evicted oldest entry: $oldestKey');
    }

    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: expiresAt,
    );

    print('[NetworkCache] Cached: $endpoint (TTL: ${ttl ?? _defaultTTL})');
  }

  /// 특정 endpoint의 캐시 무효화
  void invalidate({
    required String endpoint,
    Map<String, dynamic>? params,
  }) {
    final key = _generateKey(endpoint: endpoint, params: params);
    _cache.remove(key);
    print('[NetworkCache] Invalidated: $endpoint');
  }

  /// 패턴 매칭으로 캐시 무효화 (예: 모든 home 관련 캐시)
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    print('[NetworkCache] Invalidated pattern: $pattern (${keysToRemove.length} entries)');
  }

  /// 모든 캐시 제거
  void clear() {
    _cache.clear();
    print('[NetworkCache] All cache cleared');
  }

  /// 현재 캐시 크기
  int get size => _cache.length;

  /// 캐시 통계 (디버깅용)
  Map<String, dynamic> get stats => {
        'size': _cache.length,
        'maxSize': _maxCacheSize,
        'entries': _cache.keys.toList(),
      };
}

/// 캐시 항목
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}
