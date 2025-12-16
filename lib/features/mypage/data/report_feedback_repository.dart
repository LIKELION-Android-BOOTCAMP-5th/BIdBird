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
        .from('report')
        .select('''
          id,
          target_user_id,
          target_ci,
          report_code,
          item_id,
          report_content,
          report_status,
          created_at,
          report_feedback,
          feedbacked_at,
          items_detail(title)
        ''')
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
    final String? targetCi = row['target_ci']?.toString();
    final String reportCode = row['report_code']?.toString() ?? '';
    final String reportCodeName = getReportCodeName(row['report_code']);
    final String? itemId = row['item_id']?.toString();
    final String? itemTitle = _extractItemTitle(row['items_detail']);
    final String content = row['report_content']?.toString() ?? '';
    final int status = _parseInt(row['report_status']);
    final DateTime createdAt = _parseDateTime(row['created_at']);
    final String? feedback = row['report_feedback']?.toString();
    final DateTime? feedbackedAt = _parseNullableDateTime(row['feedbacked_at']);

    return ReportFeedbackModel(
      id: id,
      targetUserId: targetUserId,
      targetCi: targetCi,
      reportCode: reportCode,
      reportCodeName: reportCodeName,
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

  //이부분수정하기
  DateTime _parseDateTime(dynamic value) {
    // if (value is int) {
    //   return DateTime.fromMillisecondsSinceEpoch(value);
    // }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  //이부분수정하기
  DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    // if (value is int) {
    //   return DateTime.fromMillisecondsSinceEpoch(value);
    // }
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
