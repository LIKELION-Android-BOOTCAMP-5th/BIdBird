import 'package:bidbird/features/report/data/datasource/report_datasource.dart';
import 'package:bidbird/features/report/model/report_type_entity.dart';

class ReportRepository {
  ReportRepository({ReportDatasource? datasource})
      : _datasource = datasource ?? ReportDatasource();

  final ReportDatasource _datasource;

  /// code_report_type 테이블에서 모든 신고 타입 조회
  Future<List<ReportTypeEntity>> fetchReportTypes() {
    return _datasource.fetchReportTypes();
  }

  /// reports 테이블에 신고 저장
  /// target_ci는 백엔드 엣지 펑션에서 처리됨
  Future<void> submitReport({
    required String? itemId,
    required String targetUserId,
    required String reportCode,
    required String reportContent,
    List<String> imageUrls = const [],
  }) {
    return _datasource.submitReport(
      itemId: itemId,
      targetUserId: targetUserId,
      reportCode: reportCode,
      reportContent: reportContent,
      imageUrls: imageUrls,
    );
  }

  /// 사용자 정보 조회 (닉네임)
  Future<String?> fetchUserNickname(String userId) {
    return _datasource.fetchUserNickname(userId);
  }

  /// 상품 정보 조회 (제목)
  Future<String?> fetchItemTitle(String itemId) {
    return _datasource.fetchItemTitle(itemId);
  }
}

