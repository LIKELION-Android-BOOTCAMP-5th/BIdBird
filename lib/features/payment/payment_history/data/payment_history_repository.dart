import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentHistoryItem {
  PaymentHistoryItem({
    required this.itemId,
    required this.title,
    required this.amount,
    required this.paidAt,
    required this.statusCode,
    this.thumbnailUrl,
    this.paymentType,
    this.paymentId,
    this.txId,
  });

  final String itemId;
  final String title;
  final int amount;
  final DateTime paidAt;
  /// auctions.item_status_code
  final int statusCode;

   /// items_detail.thumbnail_image
  final String? thumbnailUrl;

  /// payments.payment_type (ex: 카드, Toss Pay 등)
  final String? paymentType;

  /// payments.payment_id (결제 번호)
  final String? paymentId;

  /// payments.tx_id (PG 트랜잭션 ID)
  final String? txId;

  bool get isAuctionWin => statusCode == 321;
  bool get isInstantBuy => statusCode == 322;
}

class PaymentHistoryRepository {
  PaymentHistoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<PaymentHistoryItem>> fetchMyPayments({String? itemId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // 1. payments에서 현재 사용자 결제 내역 조회
    final dynamic paymentQueryBase = _client
        .from('payments')
        .select('item_id, amount, created_at, payment_type, payment_id, tx_id')
        .eq('user_id', user.id);

    final dynamic paymentQuery = (itemId != null && itemId.isNotEmpty)
        ? paymentQueryBase.eq('item_id', itemId)
        : paymentQueryBase;

    final List<dynamic> paymentRows = await paymentQuery
        .order('created_at', ascending: false);

    if (paymentRows.isEmpty) return [];

    // 2. item_id 목록 수집
    final Set<String> itemIds = {};
    for (final row in paymentRows) {
      final itemId = row['item_id']?.toString();
      if (itemId != null && itemId.isNotEmpty) {
        itemIds.add(itemId);
      }
    }

    if (itemIds.isEmpty) return [];

    // 3. auctions에서 상태 코드 조회 (321: 경매 낙찰, 322: 즉시 구매)
    final auctionsRows = await _client
        .from('auctions')
        .select('item_id, item_status_code')
        .inFilter('item_id', itemIds.toList());

    final Map<String, int> statusByItemId = {};
    for (final row in auctionsRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final code = row['item_status_code'] as int?;
      if (code != null) {
        statusByItemId[itemId] = code;
      }
    }

    // 4. items_detail에서 제목(title) 및 썸네일 조회
    final itemDetailRows = await _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image')
        .inFilter('item_id', itemIds.toList());

    final Map<String, String> titleByItemId = {};
    final Map<String, String?> thumbnailByItemId = {};
    for (final row in itemDetailRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      titleByItemId[itemId] = row['title']?.toString() ?? '';
      thumbnailByItemId[itemId] = row['thumbnail_image']?.toString();
    }

    // 5. PaymentHistoryItem 리스트로 변환
    final List<PaymentHistoryItem> results = [];
    for (final row in paymentRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;

      final amount = (row['amount'] as num?)?.toInt() ?? 0;
      final createdAtStr = row['created_at']?.toString();
      final createdAt = DateTime.tryParse(createdAtStr ?? '') ?? DateTime.now();
      final statusCode = statusByItemId[itemId] ?? 0;
      final title = titleByItemId[itemId] ?? '';
      final thumbnailUrl = thumbnailByItemId[itemId];

      final String? paymentType = row['payment_type']?.toString();
      final String? paymentId = row['payment_id']?.toString();
      final String? txId = row['tx_id']?.toString();

      results.add(
        PaymentHistoryItem(
          itemId: itemId,
          title: title,
          amount: amount,
          paidAt: createdAt,
          statusCode: statusCode,
          thumbnailUrl: thumbnailUrl,
          paymentType: paymentType,
          paymentId: paymentId,
          txId: txId,
        ),
      );
    }

    return results;
  }
}
