import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';

class ReportFeedbackRemoteDataSource {
  ReportFeedbackRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchReports(String userId) async {
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
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.whereType<Map<String, dynamic>>().toList();
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}
