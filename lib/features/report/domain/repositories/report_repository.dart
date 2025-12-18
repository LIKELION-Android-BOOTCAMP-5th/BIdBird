import 'package:bidbird/features/report/domain/entities/report_type_entity.dart';

/// Report 도메인 리포지토리 인터페이스
abstract class ReportRepository {
  /// code_report_type 테이블에서 모든 신고 타입 조회
  Future<List<ReportTypeEntity>> fetchReportTypes();

  /// reports 테이블에 신고 저장
  /// target_ci는 백엔드 엣지 펑션에서 처리됨
  Future<void> submitReport({
    required String? itemId,
    required String targetUserId,
    required String reportCode,
    required String reportContent,
    List<String> imageUrls = const [],
  });

  /// 사용자 정보 조회 (닉네임)
  Future<String?> fetchUserNickname(String userId);

  /// 상품 정보 조회 (제목)
  Future<String?> fetchItemTitle(String itemId);
}



