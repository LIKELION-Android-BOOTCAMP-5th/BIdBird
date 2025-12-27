import 'package:bidbird/core/network/network_cache_manager.dart';
import 'package:bidbird/core/network/request_deduplicator.dart';
import 'package:bidbird/features/home/domain/entities/items_entity.dart';
import 'package:bidbird/features/home/domain/entities/keywordType_entity.dart';
import 'package:bidbird/features/home/domain/repositories/home_repository.dart'
    as domain;

import '../data_sources/home_network_api_datasource.dart';

class HomeRepositoryImpl implements domain.HomeRepository {
  final HomeNetworkApiManager _apiDatasource;
  final NetworkCacheManager _cacheManager;
  final RequestDeduplicator _deduplicator;

  HomeRepositoryImpl({
    HomeNetworkApiManager? apiDatasource,
    NetworkCacheManager? cacheManager,
    RequestDeduplicator? deduplicator,
  })  : _apiDatasource = apiDatasource ?? HomeNetworkApiManager(),
        _cacheManager = cacheManager ?? NetworkCacheManager(),
        _deduplicator = deduplicator ?? RequestDeduplicator();

  @override
  Future<List<KeywordType>> getKeywordType() {
    return _deduplicator.execute(
      method: 'RPC',
      path: 'get_keyword_types_v2',
      request: () async {
        // 캐시 확인
        final cached = _cacheManager.get<List<KeywordType>>(
          endpoint: 'get_keyword_types_v2',
        );
        if (cached != null) return cached;

        // 네트워크 호출
        final result = await _apiDatasource.getKeywordType();

        // 캐시 저장 (TTL 10분 - 키워드는 자주 변경되지 않음)
        _cacheManager.set(
          endpoint: 'get_keyword_types_v2',
          data: result,
          ttl: const Duration(minutes: 10),
        );

        return result;
      },
    );
  }

  @override
  Future<List<ItemsEntity>> fetchItems(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
    bool forceRefresh = false,
  }) {
    return _deduplicator.execute(
      method: 'RPC',
      path: 'get_home_items_v2',
      params: {
        'p_page': currentIndex,
        'p_page_size': 8,
        if (keywordType != null && keywordType != 110) 'p_keyword_id': keywordType,
      },
      request: () async {
        // forceRefresh가 아니면 캐시 확인
        if (!forceRefresh) {
          final cached = _cacheManager.get<List<ItemsEntity>>(
            endpoint: 'get_home_items_v2',
            params: {
              'p_page': currentIndex,
              'p_page_size': 8,
              if (keywordType != null && keywordType != 110) 'p_keyword_id': keywordType,
            },
          );
          if (cached != null) return cached;
        }

        // 네트워크 호출
        final result = await _apiDatasource.getItems(
          orderBy,
          currentIndex: currentIndex,
          keywordType: keywordType,
        );

        // 캐시 저장 (TTL 3분 - 경매 아이템은 자주 변경됨)
        _cacheManager.set(
          endpoint: 'get_home_items_v2',
          params: {
            'p_page': currentIndex,
            'p_page_size': 8,
            if (keywordType != null && keywordType != 110) 'p_keyword_id': keywordType,
          },
          data: result,
          ttl: const Duration(minutes: 3),
        );

        return result;
      },
    );
  }

  @override
  Future<List<ItemsEntity>> fetchSearchResult(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
    String? userInputSearchText,
    bool forceRefresh = false,
  }) {
    return _deduplicator.execute(
      method: 'RPC',
      path: 'get_home_items_v2',
      params: {
        'p_page': currentIndex,
        'p_page_size': 8,
        if (keywordType != null && keywordType != 110) 'p_keyword_id': keywordType,
        if (userInputSearchText != null && userInputSearchText.isNotEmpty)
          'p_search': userInputSearchText,
      },
      request: () async {
        // 검색은 캐시하지 않음 (사용자 입력이 매번 다름)
        // 단, 동일 검색어 중복 호출은 deduplicator가 방지
        final result = await _apiDatasource.getSearchResults(
          orderBy,
          currentIndex: currentIndex,
          keywordType: keywordType,
          userInputSearchText: userInputSearchText,
        );

        return result;
      },
    );
  }

  /// 캐시 무효화 (새로고침 시 사용)
  void invalidateCache() {
    _cacheManager.invalidatePattern('get_home_items_v2');
  }
}
