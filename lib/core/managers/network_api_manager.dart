import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/models/items_entity.dart';
import 'package:dio/dio.dart';

import '../../features/feed/model/home_data.dart';

class NetworkApiManager {
  static final NetworkApiManager _shared = NetworkApiManager();

  static NetworkApiManager get shared => _shared;
  final dio = Dio();

  NetworkApiManager() {}

  static final String supabaseUrl =
      "https://mdwelwjletorehxsptqa.supabase.co/rest/v1";
  static final String apikey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg';
  static final Map<String, dynamic> headers = {
    'apikey': apikey,
    'Authorization': SupabaseManager.shared.getAuthorizationKey(),
    'Content-Type': 'application/json',
  };

  Future<List<HomeCodeKeywordType>> getKeywordType() async {
    final response = await dio.get(
      //키워드 최신순으로 정렬
      'https://mdwelwjletorehxsptqa.supabase.co/rest/v1/code_keyword_type?select=*&order=id.asc',
      options: Options(
        headers: {
          'apikey':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg',
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg',
          'Content-Type': 'application/json',
        },
      ),
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
    int startIndex = currentIndex - 1;
    int endIndex = perPage - 1;

    // 현재 페이지가 첫 페이지가 아니라면
    if (currentIndex != 1) {
      endIndex = (currentIndex * perPage) - 1;
      startIndex = (currentIndex - 1) * perPage;
    }

    final String range = "${startIndex}-${endIndex}";

    String filterQuery = "";
    //110 이 전체 카테고리 코드
    if (keywordType != null && keywordType != 110) {
      filterQuery += "&keyword_type=eq.$keywordType";
    }

    final response = await dio.get(
      //최신순이 기본 설정
      'https://mdwelwjletorehxsptqa.supabase.co/rest/v1/items_detail?select=*,auctions!inner(bid_count,auction_start_at)&order=$orderBy&auctions.auction_start_at=not.is.null'
      '$filterQuery',
      options: Options(
        headers: {
          'apikey':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg',
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg',
          'Range': range,
        },
      ),
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
    int startIndex = currentIndex - 1;
    int endIndex = perPage - 1;

    // 현재 페이지가 첫 페이지가 아니라면
    if (currentIndex != 1) {
      endIndex = (currentIndex * perPage) - 1;
      startIndex = (currentIndex - 1) * perPage;
    }

    final String range = "${startIndex}-${endIndex}";

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
      //최신순이 기본 설정
      'https://mdwelwjletorehxsptqa.supabase.co/rest/v1/items_detail?select=*,auctions!inner(bid_count,auction_start_at)&order=$orderBy&auctions.auction_start_at=not.is.null'
      '$filterSearchText'
      '$filterQuery',
      options: Options(
        headers: {
          'apikey':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg',
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg',
          'Range': range,
        },
      ),
    );
    final List<dynamic> data = response.data;
    print("data 데이터 타입: ${data.runtimeType}");
    final List<ItemsEntity> results = data.map((json) {
      return ItemsEntity.fromJson(json);
    }).toList();

    return results;
  }
}
