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
    'Authorization': SupabaseManager.shared.getAuthorizationKey(),
    'Content-Type': 'application/json',
  };

  //이것만 사용하세요!!!!!!!!!!!!!!!!!!!!!!!11
  static Map<String, String> useThisHeaders({String? range}) {
    final newHeaders = Map<String, String>.from(headers);

    if (range != null) newHeaders['Range'] = range;

    return newHeaders;
  }
}
