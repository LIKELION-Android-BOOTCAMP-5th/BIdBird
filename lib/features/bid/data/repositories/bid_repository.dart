import 'package:bidbird/features/bid/data/datasources/bid_datasource.dart';
import 'package:bidbird/features/bid/data/datasources/bid_restriction_datasource.dart';
import 'package:bidbird/features/bid/domain/entities/bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/entities/buy_now_bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/repositories/bid_repository.dart' as domain;

/// Bid 리포지토리 구현체
class BidRepositoryImpl implements domain.BidRepository {
  BidRepositoryImpl({
    BidDatasource? bidDatasource,
    BidRestrictionDatasource? bidRestrictionDatasource,
  })  : _bidDatasource = bidDatasource ?? BidDatasource(),
        _bidRestrictionDatasource =
            bidRestrictionDatasource ?? BidRestrictionDatasource();

  final BidDatasource _bidDatasource;
  final BidRestrictionDatasource _bidRestrictionDatasource;

  @override
  Future<void> placeBid(BidRequest request) {
    return _bidDatasource.placeBid(request);
  }

  @override
  Future<void> placeBuyNowBid(BuyNowBidRequest request) {
    return _bidDatasource.placeBuyNowBid(request);
  }

  @override
  Future<bool> isBidRestricted() {
    return _bidRestrictionDatasource.isBidRestricted();
  }
}



