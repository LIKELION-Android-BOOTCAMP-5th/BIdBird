import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/core/models/items_entity.dart';
import 'package:dio/dio.dart';

import '../../model/home_data.dart';

class HomeNetworkApiManager {
  static final HomeNetworkApiManager _shared = HomeNetworkApiManager();

  static HomeNetworkApiManager get shared => _shared;
  final dio = Dio();

  HomeNetworkApiManager() {}

  Future<List<HomeCodeKeywordType>> getKeywordType() async {
    final response = await dio.get(
      //키워드 최신순으로 정렬
      '${NetworkApiManager.supabaseUrl}/code_keyword_type?select=*&order=id.asc',
      options: Options(headers: NetworkApiManager.useThisHeaders()),
    );
    final List<dynamic> data = response.data;
    print("data 데이터 타입: ${data.runtimeType}");
    final List<HomeCodeKeywordType> results = data.map((json) {
      return HomeCodeKeywordType.fromJson(json);
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

    String filterQuery = "";
    //110 이 전체 카테고리 코드
    if (keywordType != null && keywordType != 110) {
      filterQuery += "&keyword_type=eq.$keywordType";
    }

    final response = await dio.get(
      // 최신순이 기본 설정 + visibility true 필터
      '${NetworkApiManager.supabaseUrl}/items_detail?select=*,auctions!inner(bid_count,auction_start_at,last_bid_user_id,auction_status_code,trade_status_code)'
      '&visibility_status=eq.true'
      '&order=$orderBy&auctions.auction_start_at=not.is.null'
      '$filterQuery',
      options: Options(headers: NetworkApiManager.useThisHeaders(range: range)),
    );
    final List<dynamic> data = response.data;
    print("data 데이터 타입: ${data.runtimeType}");
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

    String filterQuery = "";
    //110 이 전체 카테고리 코드
    if (keywordType != null && keywordType != 110) {
      filterQuery = "&keyword_type=eq.$keywordType";
    }

    String filterSearchText = "";
    if (userInputSearchText != null && userInputSearchText.isNotEmpty) {
      filterSearchText =
          "&or=(title.ilike.*$userInputSearchText*,description.ilike.*$userInputSearchText*)";
    }

    final response = await dio.get(
      // 최신순이 기본 설정 + visibility true 필터
      '${NetworkApiManager.supabaseUrl}/items_detail?select=*,auctions!inner(bid_count,auction_start_at,last_bid_user_id,auction_status_code,trade_status_code)'
      '&visibility_status=eq.true'
      '&order=$orderBy&auctions.auction_start_at=not.is.null'
      '$filterSearchText'
      '$filterQuery',
      options: Options(headers: NetworkApiManager.useThisHeaders(range: range)),
    );
    final List<dynamic> data = response.data;
    print("data 데이터 타입: ${data.runtimeType}");
    final List<ItemsEntity> results = data.map((json) {
      return ItemsEntity.fromJson(json);
    }).toList();

    return results;
  }
}