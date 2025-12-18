import 'package:bidbird/features/payment/payment_history/data/datasources/payment_history_datasource.dart';
import 'package:bidbird/features/payment/payment_history/domain/entities/payment_history_entity.dart';
import 'package:bidbird/features/payment/payment_history/domain/repositories/payment_history_repository.dart' as domain;

/// 결제 내역 리포지토리 구현체
class PaymentHistoryRepositoryImpl implements domain.PaymentHistoryRepository {
  PaymentHistoryRepositoryImpl({PaymentHistoryDatasource? datasource})
      : _datasource = datasource ?? PaymentHistoryDatasource();

  final PaymentHistoryDatasource _datasource;

  @override
  Future<List<PaymentHistoryItem>> fetchMyPayments({String? itemId}) async {
    // 1. payments에서 결제 내역 조회
    final paymentRows = await _datasource.fetchPayments(itemId: itemId);
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

    // 3. 병렬로 상태 코드 및 아이템 정보 조회
    final results = await Future.wait([
      _datasource.fetchStatusCodes(itemIds.toList()),
      _datasource.fetchItemDetails(itemIds.toList()),
    ]);

    final statusByItemId = results[0] as Map<String, int>;
    final itemDetailsByItemId = results[1] as Map<String, Map<String, String?>>;

    // 4. PaymentHistoryItem 리스트로 변환
    final List<PaymentHistoryItem> paymentHistoryItems = [];
    for (final row in paymentRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;

      final amount = (row['amount'] as num?)?.toInt() ?? 0;
      final createdAtStr = row['created_at']?.toString();
      final createdAt = DateTime.tryParse(createdAtStr ?? '') ?? DateTime.now();
      final statusCode = statusByItemId[itemId] ?? 0;
      
      final itemDetails = itemDetailsByItemId[itemId];
      final title = itemDetails?['title'] ?? '';
      final thumbnailUrl = itemDetails?['thumbnail'];

      final String? paymentType = row['payment_type']?.toString();
      final String? paymentId = row['payment_id']?.toString();
      final String? txId = row['tx_id']?.toString();

      paymentHistoryItems.add(
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

    return paymentHistoryItems;
  }
}



