import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/detail/data/datasource/item_detail_datasource.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../item_detail_utils.dart';

class ItemDescriptionSection extends StatelessWidget {
  const ItemDescriptionSection({required this.item, super.key});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: BorderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: yellowColor,
                      child: Icon(Icons.person, color: BackgroundColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.sellerTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: yellowColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.sellerRating.toStringAsFixed(1)} (${item.sellerReviewCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (item.sellerId.isEmpty) return;
                        context.push('/user/${item.sellerId}');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(0, 0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '프로필 보기',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: blueColor,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: blueColor),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: BorderColor),
                const SizedBox(height: 12),
                const Text(
                  '상품 설명',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  item.itemContent,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: BorderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현재 입찰 내역',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: ItemDetailDatasource().fetchBidHistory(item.itemId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text(
                        '입찰 내역을 불러올 수 없습니다.',
                        style: TextStyle(fontSize: 12, color: iconColor),
                      );
                    }

                    final bids = snapshot.data ?? [];

                    // 가격이 0원인 입찰은 표시하지 않음
                    final filteredBids = bids.where((bid) {
                      final dynamic rawPrice = bid['price'];
                      if (rawPrice == null) return false;
                      if (rawPrice is num) {
                        return rawPrice != 0;
                      }
                      final parsed = int.tryParse(rawPrice.toString());
                      return parsed != null && parsed != 0;
                    }).toList();

                    if (filteredBids.isEmpty) {
                      return const Text(
                        '아직 입찰 내역이 없습니다.',
                        style: TextStyle(fontSize: 12, color: iconColor),
                      );
                    }

                    final limited = filteredBids.take(10).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: limited.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final bid = limited[index];
                        final price = bid['price']?.toString() ?? '';
                        final createdAtRaw = bid['created_at']?.toString();
                        final relative = formatRelativeTime(createdAtRaw);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${index + 1}. $price원',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              relative,
                              style: const TextStyle(
                                fontSize: 11,
                                color: iconColor,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
