import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/report_feedback_model.dart';

class ReportFeedbackRepository {
  ReportFeedbackRepository({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<ReportFeedbackModel>> fetchReports() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final List<dynamic> rows = await _client
        .from('reports')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List<ReportFeedbackModel> reports = [];
    for (final dynamic row in rows) {
      if (row is Map<String, dynamic>) {
        reports.add(await _mapReport(row));
      }
    }

    return reports;
  }

  //개별아이템에대한당겨서새로고침기능을추가하는경우필요함
  // Future<ReportFeedbackModel?> fetchReportById(String id) async {
  //   if (id.isEmpty) return null;

  //   final Map<String, dynamic>? row = await _client
  //       .from('reports')
  //       .select()
  //       .eq('id', id)
  //       .maybeSingle();

  //   if (row == null) return null;
  //   return _mapReport(row);
  // }

  Future<ReportFeedbackModel> _mapReport(Map<String, dynamic> row) async {
    final String id = row['id']?.toString() ?? '';
    final String targetUserId = row['target_user_id']?.toString() ?? '';
    final String targetUserNickname =
        row['target_user_nickname']?.toString() ?? '';
    final String reportTypeId = row['report_type_id']?.toString() ?? '';
    final String reportTypeName = getReportStatusString(row['report_type_id']);
    final String? itemId = row['item_id']?.toString();
    final String? itemTitle = row['item_title']?.toString();
    final String content = row['report_content']?.toString() ?? '';
    final int status = (row['report_status'] as int?) ?? 0;
    final DateTime createdAt = _parseDateTime(row['created_at']);
    final String? feedback = row['report_feedback']?.toString();
    final DateTime? feedbackedAt = _parseNullableDateTime(row['feedbacked_at']);

    return ReportFeedbackModel(
      id: id,
      targetUserId: targetUserId,
      targetUserNickname: targetUserNickname,
      reportTypeId: reportTypeId,
      reportTypeName: reportTypeName,
      itemId: itemId,
      itemTitle: itemTitle,
      content: content,
      status: status,
      createdAt: createdAt,
      feedback: feedback,
      feedbackedAt: feedbackedAt,
    );
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
