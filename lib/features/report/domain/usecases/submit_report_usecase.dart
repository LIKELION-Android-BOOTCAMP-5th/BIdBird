import 'package:bidbird/features/report/domain/repositories/report_repository.dart';

/// 신고 제출 유즈케이스
class SubmitReportUseCase {
  SubmitReportUseCase(this._repository);

  final ReportRepository _repository;

  Future<void> call({
    required String? itemId,
    required String targetUserId,
    required String reportCode,
    required String reportContent,
    List<String> imageUrls = const [],
  }) {
    return _repository.submitReport(
      itemId: itemId,
      targetUserId: targetUserId,
      reportCode: reportCode,
      reportContent: reportContent,
      imageUrls: imageUrls,
    );
  }
}

