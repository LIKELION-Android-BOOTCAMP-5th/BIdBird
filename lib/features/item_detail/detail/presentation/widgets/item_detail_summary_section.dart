import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label - 현재 입찰가
          Text(
            '현재 입찰가',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7684), // Secondary Text
            ),
          ),
          const SizedBox(height: 4),
          // 가격과 판매자 연락 버튼을 Row로 배치 (같은 높이)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Metric Value - 큰 숫자
              Expanded(
                child: Text(
                  '${formatPrice(item.currentPrice)} 원',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: Color(0xFF191F28), // Primary Text
                  ),
                ),
              ),
              // 판매자 연락 버튼 - 동그라미 아이콘
              if (!isMyItem && !isAuctionExpired)
                Material(
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182F6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Color(0xFF3182F6), // Primary Blue
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Metric Sub - 한 줄, Tertiary 컬러
          Text(
            item.buyNowPrice > 0 ? '즉시 구매가 ${formatPrice(item.buyNowPrice)}원' : '즉시 구매 불가',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF), // Tertiary
            ),
          ),
          const SizedBox(height: 20),
          // Divider
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

