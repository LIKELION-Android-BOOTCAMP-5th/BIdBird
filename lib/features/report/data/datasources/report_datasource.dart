import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/report/domain/entities/report_type_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDatasource {
  ReportDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  /// code_report_type 테이블에서 모든 신고 타입 조회
  Future<List<ReportTypeEntity>> fetchReportTypes() async {
    try {
      final response = await _supabase
          .from('code_report_type')
          .select('report_type, text')
          .order('report_type');

      final List<dynamic> data = response as List<dynamic>;
      
      if (data.isEmpty) {
        return [];
      }

      final result = <ReportTypeEntity>[];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          try {
            final entity = ReportTypeEntity.fromJson(item);
            result.add(entity);
          } catch (e) {
            // 파싱 에러 발생 시 해당 항목 건너뛰기
          }
        }
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// reports 테이블에 신고 저장
  /// target_ci는 백엔드 엣지 펑션에서 처리됨
  Future<void> submitReport({
    required String? itemId,
    required String targetUserId,
    required String reportCode,
    required String reportContent,
    List<String> imageUrls = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      // 엣지 펑션 호출
      final response = await _supabase.functions.invoke(
        'submit-report',
        body: {
          'item_id': itemId,
          'target_user_id': targetUserId,
          'report_code': reportCode,
          'report_content': reportContent,
          'user_id': user.id,
          'image_urls': imageUrls,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] != true) {
          final errorMessage = data['error'] ?? '신고 제출에 실패했습니다.';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('신고 제출에 실패했습니다.');
      }
    } catch (e) {
      // 에러 메시지에서 사용자 친화적인 메시지 추출
      final errorString = e.toString();
      if (errorString.contains('신고 저장에 실패했습니다')) {
        throw Exception('신고 저장에 실패했습니다.\n잠시 후 다시 시도해주세요.');
      } else if (errorString.contains('신고 대상 사용자를 찾을 수 없습니다')) {
        throw Exception('신고 대상 사용자를 찾을 수 없습니다.');
      } else if (errorString.contains('필수 파라미터가 누락되었습니다')) {
        throw Exception('필수 정보가 누락되었습니다.\n모든 항목을 입력해주세요.');
      } else if (errorString.contains('서버 오류')) {
        throw Exception('서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('신고 제출에 실패했습니다.\n잠시 후 다시 시도해주세요.');
      }
    }
  }

  /// 사용자 정보 조회 (닉네임)
  Future<String?> fetchUserNickname(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('nick_name')
          .eq('id', userId)
          .maybeSingle();

      return data?['nick_name'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 상품 정보 조회 (제목)
  Future<String?> fetchItemTitle(String itemId) async {
    try {
      final data = await _supabase
          .from('items_detail')
          .select('title')
          .eq('item_id', itemId)
          .maybeSingle();

      return data?['title'] as String?;
    } catch (e) {
      return null;
    }
  }
}



