import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 결제 내역 데이터 소스
class PaymentHistoryDatasource {
  PaymentHistoryDatasource({SupabaseClient? client})
      : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  /// 결제 내역 조회
  Future<List<Map<String, dynamic>>> fetchPayments({String? itemId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final dynamic paymentQueryBase = _client
        .from('payments')
        .select('item_id, amount, created_at, payment_type, payment_id, tx_id')
        .eq('user_id', user.id);

    final dynamic paymentQuery = (itemId != null && itemId.isNotEmpty)
        ? paymentQueryBase.eq('item_id', itemId)
        : paymentQueryBase;

    final List<dynamic> paymentRows = await paymentQuery
        .order('created_at', ascending: false);

    return paymentRows.map((row) => row as Map<String, dynamic>).toList();
  }

  /// 경매 상태 코드 조회
  Future<Map<String, int>> fetchStatusCodes(List<String> itemIds) async {
    if (itemIds.isEmpty) return {};

    final auctionsRows = await _client
        .from('auctions')
        .select('item_id, item_status_code')
        .inFilter('item_id', itemIds);

    final Map<String, int> statusByItemId = {};
    for (final row in auctionsRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final code = row['item_status_code'] as int?;
      if (code != null) {
        statusByItemId[itemId] = code;
      }
    }

    return statusByItemId;
  }

  /// 아이템 정보 조회 (제목, 썸네일)
  Future<Map<String, Map<String, String?>>> fetchItemDetails(List<String> itemIds) async {
    if (itemIds.isEmpty) return {};

    final itemDetailRows = await _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image')
        .inFilter('item_id', itemIds);

    final Map<String, Map<String, String?>> result = {};
    for (final row in itemDetailRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      result[itemId] = {
        'title': row['title']?.toString() ?? '',
        'thumbnail': row['thumbnail_image']?.toString(),
      };
    }

    return result;
  }
}



