import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemDetailSummarySection extends StatelessWidget {
  const ItemDetailSummarySection({
    required this.item,
    required this.isMyItem,
    super.key,
  });

  final ItemDetail item;
  final bool isMyItem;

  @override
  Widget build(BuildContext context) {
    // 경매 만료 여부 확인
    final bool isTimeOver = DateTime.now().isAfter(item.finishTime);
    final bool isAuctionEnded = isTimeOver ||
        item.statusCode == AuctionStatusCode.bidWon ||
        item.statusCode == AuctionStatusCode.instantBuyCompleted ||
        item.statusCode == AuctionStatusCode.failed;
    final bool isAuctionExpired = isAuctionEnded;

    // Section Container - padding 24
    final horizontalPadding = context.screenPadding;
    final spacingSmall = context.spacingSmall;
    final spacingMedium = context.spacingMedium;
    final priceFontSize = context.widthRatio(0.085, min: 26.0, max: 36.0);
    final labelFontSize = context.fontSizeSmall;
    final subtitleFontSize = context.fontSizeSmall;
    final isCompact = context.isSmallScreen(threshold: 360);

    Widget buildContactButton() {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChattingRoomScreen(itemId: item.itemId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacingSmall * 1.5,
              vertical: spacingSmall * 0.7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF3182F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '판매자 연락',
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3182F6),
                  ),
                ),
                SizedBox(width: spacingSmall * 0.6),
                Icon(
                  Icons.message,
                  size: context.iconSizeSmall,
                  color: const Color(0xFF3182F6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final contactButton = (!isMyItem && !isAuctionExpired) ? buildContactButton() : null;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 입찰가',
            style: TextStyle(
              fontSize: labelFontSize,
              color: const Color(0xFF6B7684),
            ),
          ),
          SizedBox(height: spacingSmall * 0.5),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatPrice(item.currentPrice)} 원',
                  style: TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: const Color(0xFF191F28),
                  ),
                ),
                if (contactButton != null) ...[
                  SizedBox(height: spacingSmall),
                  contactButton,
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '${formatPrice(item.currentPrice)} 원',
                    style: TextStyle(
                      fontSize: priceFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: const Color(0xFF191F28),
                    ),
                  ),
                ),
                if (contactButton != null) contactButton,
              ],
            ),
          SizedBox(height: spacingSmall * 0.6),
          Text(
            item.buyNowPrice > 0
                ? '즉시 구매가 ${formatPrice(item.buyNowPrice)}원'
                : '즉시 구매 불가',
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: spacingMedium),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}

