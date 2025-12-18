import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';

/// 결제 처리 리포지토리 인터페이스
abstract class ItemPaymentRepository {
  /// 결제 결과 처리
  /// 
  /// [result] Portone 결제 결과
  /// [request] 결제 요청 정보
  /// 
  /// Returns 결제 성공 여부
  Future<bool> handlePaymentResult({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  });
}



