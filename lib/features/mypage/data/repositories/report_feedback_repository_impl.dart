import '../../domain/entities/report_feedback_entity.dart';
import '../../domain/repositories/report_feedback_repository.dart';
import '../datasources/report_feedback_remote_data_source.dart';
import '../models/report_feedback_dto.dart';

class ReportFeedbackRepositoryImpl implements ReportFeedbackRepository {
  ReportFeedbackRepositoryImpl({ReportFeedbackRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ReportFeedbackRemoteDataSource();

  final ReportFeedbackRemoteDataSource _remoteDataSource;

  @override
  Future<List<ReportFeedbackEntity>> fetchReports() async {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final rows = await _remoteDataSource.fetchReports(userId);

    final List<ReportFeedbackDto> reports = [];
    for (final row in rows) {
      reports.add(_mapReport(row));
    }

    return reports.map((dto) => dto.toEntity()).toList();
  }

  ReportFeedbackDto _mapReport(Map<String, dynamic> row) {
    final String id = row['id']?.toString() ?? '';
    final String targetUserId = row['target_user_id']?.toString() ?? '';
    final String? targetCi = row['target_ci']?.toString();
    final String reportCode = row['report_code']?.toString() ?? '';
    final String? itemId = row['item_id']?.toString();
    final String? itemTitle = _extractItemTitle(row['items_detail']);
    final String content = row['report_content']?.toString() ?? '';
    final int status = _parseInt(row['report_status']);
    final DateTime createdAt = _parseDateTime(row['created_at']);
    final String? feedback = row['report_feedback']?.toString();
    final DateTime? feedbackedAt = _parseNullableDateTime(row['feedbacked_at']);

    return ReportFeedbackDto(
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

  String? _extractItemTitle(dynamic itemsDetail) {
    if (itemsDetail is Map<String, dynamic>) {
      final dynamic title = itemsDetail['title'];
      return title?.toString();
    }

    if (itemsDetail is List && itemsDetail.isNotEmpty) {
      final dynamic first = itemsDetail.first;
      if (first is Map<String, dynamic>) {
        final dynamic title = first['title'];
        return title?.toString();
      }
    }

    return null;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal();
    }
    return null;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
