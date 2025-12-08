import 'package:bidbird/core/models/items_entity.dart';
import 'package:dio/dio.dart';

import '../../features/feed/model/home_data.dart';

class NetworkApiManager {
  static final NetworkApiManager _shared = NetworkApiManager();

  static NetworkApiManager get shared => _shared;
  final dio = Dio();

  NetworkApiManager() {}

  Future<List<HomeCodeKeywordType>> getKeywordType() async {
    final response = await dio.get(
      'https://mdwelwjletorehxsptqa.supabase.co/rest/v1/code_keyword_type?select=*',
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

  Future<List<ItemsEntity>> getItems({
    int currentIndex = 1,
    int perPage = 8,
  }) async {
    int startIndex = currentIndex - 1;
    int endIndex = perPage - 1;

    // 현재 페이지가 첫 페이지가 아니라면
    if (currentIndex != 1) {
      endIndex = (currentIndex * perPage) - 1;
      startIndex = (currentIndex - 1) * perPage;
    }

    final String range = "${startIndex}-${endIndex}";

    final response = await dio.get(
      'https://mdwelwjletorehxsptqa.supabase.co/rest/v1/items?select=*',
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
