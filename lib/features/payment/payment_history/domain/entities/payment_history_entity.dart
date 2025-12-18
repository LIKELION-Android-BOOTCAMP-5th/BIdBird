import 'package:bidbird/core/utils/payment/payment_constants.dart';

/// 결제 내역 엔티티
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

  bool get isAuctionWin => statusCode == PaymentStatusCodes.auctionWin;
  bool get isInstantBuy => statusCode == PaymentStatusCodes.instantBuy;
}

