import '../../../core/managers/supabase_manager.dart';

class TermsRepository {
  final _client = SupabaseManager.shared.supabase;

  Future<String> fetchLatestTermsContent() async {
    try {
      final response = await _client
          .from('tos')
          .select('content, created_at')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed fetchLatestTermsContent');
      }

      final content = response['content'];
      if (content is! String || content.isEmpty) {
        throw Exception('Failed fetchLatestTermsContent');
      }

      return content;
    } catch (e) {
      throw Exception('Failed fetchLatestTermsContent: $e');
    }
  }
}
