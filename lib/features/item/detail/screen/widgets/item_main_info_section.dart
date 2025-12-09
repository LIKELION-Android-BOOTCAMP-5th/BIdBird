import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../item_detail_utils.dart';

class ItemMainInfoSection extends StatelessWidget {
  const ItemMainInfoSection({
    required this.item,
    required this.isMyItem,
    super.key,
  });

  final ItemDetail item;
  final bool isMyItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.buyNowPrice > 0
                          ? '즉시 구매가 ${formatPrice(item.buyNowPrice)}원'
                          : '즉시 구매 없음',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.buyNowPrice > 0 ? blueColor : iconColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isMyItem)
                TextButton.icon(
                  onPressed: () {
                    // TODO: 판매자 연락 기능 연동 (채팅 등)
                    context.push('/chat/room?itemId=${item.itemId}');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: blueColor,
                  ),
                  label: const Text(
                    '판매자 연락',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: blueColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: BorderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: const [],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '현재 입찰가',
                        style: TextStyle(fontSize: 12, color: iconColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatPrice(item.currentPrice)}원',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: BorderColor.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '참여 입찰',
                        style: TextStyle(fontSize: 12, color: iconColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.biddingCount}건',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
