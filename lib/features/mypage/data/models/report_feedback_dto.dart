import '../../domain/entities/report_feedback_entity.dart';

class ReportFeedbackDto {
  const ReportFeedbackDto({
    required this.id,
    required this.targetUserId,
    required this.targetCi,
    required this.reportCode,
    required this.itemId,
    required this.itemTitle,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.feedback,
    required this.feedbackedAt,
  });

  final String id;
  final String targetUserId;
  final String? targetCi;
  final String reportCode;
  final String? itemId;
  final String? itemTitle;
  final String content;
  final int status;
  final DateTime createdAt;
  final String? feedback;
  final DateTime? feedbackedAt;

  ReportFeedbackEntity toEntity() {
    return ReportFeedbackEntity(
      id: id,
      targetUserId: targetUserId,
      targetCi: targetCi,
      reportCode: reportCode,
      itemId: itemId,
      itemTitle: itemTitle,
      content: content,
      status: status,
      createdAt: createdAt,
      feedback: feedback,
      feedbackedAt: feedbackedAt,
    );
  }
}
