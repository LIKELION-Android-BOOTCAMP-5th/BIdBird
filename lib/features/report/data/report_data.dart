import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> insertReport({
    required String itemId,
    required String targetUserId,
    required String targetUserNickname,
    required int reportTypeId,
    required String reportContent,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      print(" 로그인 정보 없음");
      return false;
    }

    try {
      final response = await _client.from("reports").insert({
        "item_id": itemId,
        "target_user_id": targetUserId,
        "target_user_nickname": targetUserNickname,
        "user_id": user.id,
        "report_type_id": reportTypeId,
        "report_content": reportContent,
        "report_status": 1, // 기본 접수 상태
      }).select();

      print(" 성공: $response");
      return response.isNotEmpty;
    } catch (error) {
      print(" Supabase 에러 발생: $error");
      return false;
    }
  }



  int reportTypeId(String reason) {
    switch (reason) {
      case "사기 / 안전거래 위반":
        return 1;
      case "욕설 / 비매너":
        return 2;
      case "광고 / 스팸":
        return 3;
      case "부적절한 내용":
        return 4;
      default:
        return 99; // 기타
    }
  }
}
