import 'package:bidbird/core/models/keywordType_entity.dart';
import 'package:dio/dio.dart';

import '../../../../core/managers/network_api_manager.dart';

class ProfileNetworkApiDatasource {
  static final ProfileNetworkApiDatasource _shared =
      ProfileNetworkApiDatasource();
  static ProfileNetworkApiDatasource get shared => _shared;

  final dio = Dio();
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
}
