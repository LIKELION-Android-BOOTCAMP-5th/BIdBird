import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/items_entity.dart';
import '../../domain/entities/keywordType_entity.dart';

class HomeNetworkApiManager {
  static final HomeNetworkApiManager _shared = HomeNetworkApiManager();

  static HomeNetworkApiManager get shared => _shared;
  final dio = Dio();
  final _supabase = SupabaseManager.shared.supabase;

  HomeNetworkApiManager();

  Future<List<KeywordType>> getKeywordType() async {
    try {
      final response = await _supabase.rpc('get_keyword_types_v2');

      if (response is Map && response.containsKey('error')) {
        throw Exception('Failed to fetch keyword types: ${response['error']}');
      }

      if (response is List) {
        return response.map((json) => KeywordType.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch keyword types: $e');
    }
  }

  Future<List<ItemsEntity>> getItems(
    String orderBy, {
    int currentIndex = 1,
    int perPage = 8,
    int? keywordType,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_home_items_v2',
        params: {
          'p_page': currentIndex,
          'p_page_size': perPage,
          if (keywordType != null && keywordType != 110)
            'p_keyword_id': keywordType,
        },
      );

      // 에러 응답 처리
      if (response is Map && response.containsKey('error')) {
        throw Exception('RPC Error: ${response['error']}');
      }

      // 정상 응답 처리
      if (response is Map && response.containsKey('items')) {
        final List<dynamic> items = response['items'];
        return items.map((json) => ItemsEntity.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }

  Future<List<ItemsEntity>> getSearchResults(
    String orderBy, {
    int currentIndex = 1,
    int perPage = 8,
    int? keywordType,
    String? userInputSearchText,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_home_items_v2',
        params: {
          'p_page': currentIndex,
          'p_page_size': perPage,
          if (keywordType != null && keywordType != 110)
            'p_keyword_id': keywordType,
          if (userInputSearchText != null && userInputSearchText.isNotEmpty)
            'p_search': userInputSearchText,
        },
      );

      // 에러 응답 처리
      if (response is Map && response.containsKey('error')) {
        throw Exception('RPC Error: ${response['error']}');
      }

      // 정상 응답 처리
      if (response is Map && response.containsKey('items')) {
        final List<dynamic> items = response['items'];
        return items.map((json) => ItemsEntity.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch search results: $e');
    }
  }
}
