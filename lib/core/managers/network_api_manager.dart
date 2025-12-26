import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkApiManager {
  static final NetworkApiManager _shared = NetworkApiManager();

  static NetworkApiManager get shared => _shared;
  final dio = Dio();

  NetworkApiManager();

  static String get supabaseUrl {
    final client = Supabase.instance.client;
    return '${client.supabaseUrl}/rest/v1';
  }

  static String get apiKey => Supabase.instance.client.supabaseAnonKey;


  static final Map<String, String> headers = {
    'apikey': apiKey,
    // 'Authorization': SupabaseManager.shared.getAuthorizationKey(),
    'Content-Type': 'application/json',
  };

  //이것만 사용하세요!!!!!!!!!!!!!!!!!!!!!!!11 range 설정 안하는거면 그냥 안쓰면 됩니다
  static Map<String, String> useThisHeaders({String? range}) {
    final newHeaders = Map<String, String>.from(headers);

    if (range != null) newHeaders['Range'] = range;
    newHeaders['Authorization'] = SupabaseManager.shared.getAuthorizationKey();
    return newHeaders;
  }

  //페이징 계산 로직
  static String useThisPagingLogic({
    required int currentIndex,
    required int perPage,
  }) {
    int startIndex = currentIndex - 1;
    int endIndex = perPage - 1;

    // 현재 페이지가 첫 페이지가 아니라면
    if (currentIndex != 1) {
      endIndex = (currentIndex * perPage) - 1;
      startIndex = (currentIndex - 1) * perPage;
    }
    return "$startIndex-$endIndex";
  }

  //체크해서 url이나 apiKey가 없으면 바로 터지게 하는 로직
  void checkEnv() {
    assert(
      NetworkApiManager.supabaseUrl.isNotEmpty,
      'SUPABASE_API_URL (or SUPABASE_URL) is missing',
    );

    assert(NetworkApiManager.apiKey.isNotEmpty, 'SUPABASE_ANON_KEY is missing');
  }
}
