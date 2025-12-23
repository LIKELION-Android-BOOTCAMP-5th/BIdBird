import 'package:bidbird/features/report/domain/usecases/submit_report_usecase.dart';
import 'package:image_picker/image_picker.dart';

/// Report Flow 성공 결과
class ReportFlowSuccess {
  final String reportId;
  final String message;

  const ReportFlowSuccess({
    required this.reportId,
    required this.message,
  });
}

/// Report Flow 실패 결과
class ReportFlowFailure {
  final String message;

  const ReportFlowFailure(this.message);
}

/// Report 제출 오케스트레이션 UseCase
/// 
/// 여러 UseCase를 조합하여 Report 제출 프로세스를 처리합니다.
/// - 이미지 업로드 (선택사항)
/// - Report 제출
/// - 결과 반환 (성공/실패)
class ReportFlowUseCase {
  const ReportFlowUseCase({
    required SubmitReportUseCase submitReportUseCase,
  }) : _submitReportUseCase = submitReportUseCase;

  final SubmitReportUseCase _submitReportUseCase;

  /// Report 제출 오케스트레이션
  /// 
  /// Returns: (성공 결과, 실패 결과)
  /// - 성공 시: (ReportFlowSuccess, null)
  /// - 실패 시: (null, ReportFlowFailure)
  Future<(ReportFlowSuccess?, ReportFlowFailure?)> submit({
    required String? itemId,
    required String targetUserId,
    required String reportCode,
    required String reportContent,
    required List<XFile> images,
  }) async {
    try {
      // 이미지 업로드는 여기서 처리 (현재는 reportContent에 포함됨)
      // 향후: UploadImagesUseCase를 추가할 수 있음
      // List<String> imageUrls = [];
      // if (images.isNotEmpty) {
      //   imageUrls = await _uploadImagesUseCase(images);
      // }

      // Step: Report 제출
      await _submitReportUseCase(
        itemId: itemId,
        targetUserId: targetUserId,
        reportCode: reportCode,
        reportContent: reportContent,
        imageUrls: [], // 현재는 빈 리스트
      );

      // 성공 반환
      return (
        const ReportFlowSuccess(
          reportId: 'generated-id',
          message: '신고가 접수되었습니다.',
        ),
        null,
      );
    } catch (e) {
      return (
        null,
        ReportFlowFailure(e.toString()),
      );
    }
  }
}
