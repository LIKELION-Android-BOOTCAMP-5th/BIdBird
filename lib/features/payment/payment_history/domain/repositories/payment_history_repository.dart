import 'package:bidbird/features/payment/payment_history/domain/entities/payment_history_entity.dart';

/// 결제 내역 리포지토리 인터페이스
abstract class PaymentHistoryRepository {
  /// 내 결제 내역 조회
  /// 
  /// [itemId] 특정 아이템의 결제 내역만 조회 (null이면 전체)
  Future<List<PaymentHistoryItem>> fetchMyPayments({String? itemId});
}



