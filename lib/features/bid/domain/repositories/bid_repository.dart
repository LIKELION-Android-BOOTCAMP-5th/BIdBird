import 'package:bidbird/features/bid/domain/entities/bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/entities/buy_now_bid_request_entity.dart';

/// Bid 도메인 리포지토리 인터페이스
abstract class BidRepository {
  /// 일반 입찰 실행
  Future<void> placeBid(BidRequest request);
  
  // /// 즉시 구매 입찰 실행
  // Future<void> placeBuyNowBid(BuyNowBidRequest request);
  
  /// 입찰 제한 여부 확인 (true면 제한됨)
  Future<bool> isBidRestricted();
}



