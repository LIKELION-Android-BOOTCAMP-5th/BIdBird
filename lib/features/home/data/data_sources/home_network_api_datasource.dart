import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/items_entity.dart';
import '../../domain/entities/keywordType_entity.dart';

class HomeNetworkApiManager {
  static final HomeNetworkApiManager _shared = HomeNetworkApiManager();

  static HomeNetworkApiManager get shared => _shared;
  final dio = Dio();

  HomeNetworkApiManager() {}

  Future<List<KeywordType>> getKeywordType() async {
    final response = await dio.get(
      //키워드 최신순으로 정렬
      '${NetworkApiManager.supabaseUrl}/code_keyword_type?select=*&order=id.asc',
      options: Options(headers: NetworkApiManager.useThisHeaders()),
    );
    final List<dynamic> data = response.data;
    print("data 데이터 타입: ${data.runtimeType}");
    final List<KeywordType> results = data.map((json) {
      return KeywordType.fromJson(json);
    }).toList();

    return results;
  }

  Future<List<ItemsEntity>> getItems(
    String orderBy, {
    int currentIndex = 1,
    int perPage = 8,
    int? keywordType,
  }) async {
    final String range = NetworkApiManager.useThisPagingLogic(
      currentIndex: currentIndex,
      perPage: perPage,
    );

    // 쿼리 조건 정리
    String keywordFilter = "";
    if (keywordType != null && keywordType != 110) {
      keywordFilter = "&keyword_type=eq.$keywordType";
    }

    // 통합 쿼리: visibility_status=true, auction_start_at이 존재하는 모든 매물
    final response = await dio.get(
      '${NetworkApiManager.supabaseUrl}/items_detail?'
      'select=*,auctions!inner(current_price,bid_count,auction_start_at,auction_end_at,last_bid_user_id,auction_status_code,trade_status_code)'
      '&visibility_status=is.true'
      '&auctions.auction_start_at=not.is.null'
      '$keywordFilter'
      '&order=$orderBy',
      options: Options(headers: NetworkApiManager.useThisHeaders(range: range)),
    );
    
    final List<dynamic> data = response.data;
    print("getItems 응답 개수: ${data.length}");
    final List<ItemsEntity> results = data.map((json) {
      return ItemsEntity.fromJson(json);
    }).toList();

    return results;
  }

  Future<List<ItemsEntity>> getSearchResults(
    String orderBy, {
    int currentIndex = 1,
    int perPage = 8,
    int? keywordType,
    String? userInputSearchText,
  }) async {
    final String range = NetworkApiManager.useThisPagingLogic(
      currentIndex: currentIndex,
      perPage: perPage,
    );

    // 쿼리 조건 정리
    String keywordFilter = "";
    if (keywordType != null && keywordType != 110) {
      keywordFilter = "&keyword_type=eq.$keywordType";
    }

    String searchFilter = "";
    if (userInputSearchText != null && userInputSearchText.isNotEmpty) {
      searchFilter = "&or=(title.ilike.*$userInputSearchText*,description.ilike.*$userInputSearchText*)";
    }

    // 통합 쿼리: visibility_status=true, auction_start_at이 존재하는 모든 매물
    final response = await dio.get(
      '${NetworkApiManager.supabaseUrl}/items_detail?'
      'select=*,auctions!inner(current_price,bid_count,auction_start_at,auction_end_at,last_bid_user_id,auction_status_code,trade_status_code)'
      '&visibility_status=is.true'
      '&auctions.auction_start_at=not.is.null'
      '$searchFilter'
      '$keywordFilter'
      '&order=$orderBy',
      options: Options(headers: NetworkApiManager.useThisHeaders(range: range)),
    );
    
    final List<dynamic> data = response.data;
    print("getSearchResults 응답 개수: ${data.length}");
    final List<ItemsEntity> results = data.map((json) {
      return ItemsEntity.fromJson(json);
    }).toList();

    return results;
  }
}
