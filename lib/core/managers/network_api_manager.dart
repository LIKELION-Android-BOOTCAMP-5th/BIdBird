import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:dio/dio.dart';

class NetworkApiManager {
  static final NetworkApiManager _shared = NetworkApiManager();

  static NetworkApiManager get shared => _shared;
  final dio = Dio();

  NetworkApiManager() {}

  //위에것은 걍 정의하는 것임
  static final String supabaseUrl =
      "https://mdwelwjletorehxsptqa.supabase.co/rest/v1";
  static final String apikey = 'sb_publishable_NQq1CoDOtr9FkfOSod8VHA_aqMLFp0x';

  static final Map<String, String> headers = {
    'apikey': apikey,
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
}
