import 'package:bidbird/core/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeHistoryRepository {
  final SupabaseClient _supabase;

  TradeHistoryRepository() : _supabase = SupabaseManager.shared.supabase;

  Future<List<Map<String, String>>> fetchBidHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final bidLogs = await _supabase
          .from('bid_log')
          .select('*, items!inner(*)')
          .eq('bid_user', user.id)
          .order('bid_time', ascending: false);

      if (bidLogs == null || bidLogs.isEmpty) {
        return [];
      }

      return bidLogs.map<Map<String, String>>((log) {
        final item = log['items'] as Map<String, dynamic>;
        return {
          'item_id': log['item_id']?.toString() ?? '',
          'title': item['title']?.toString() ?? '제목 없음',
          'price': '${log['bid_price']?.toString() ?? '0'}원',
          'status': '입찰 중',
          'date': _formatDateTime(log['bid_time']?.toString()),
        };
      }).toList();
    } catch (e) {
      print('Error fetching bid history: $e');
      rethrow;
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void updateSellerTitle(String? nickname) {
    String sellerTitle = '';
    if (nickname != null && nickname.isNotEmpty) {
      sellerTitle = nickname;
    } else {
      sellerTitle = '미지정 사용자';
    }
  }
}
