import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/core/utils/item/item_time_utils.dart';

class ItemDescriptionSection extends StatefulWidget {
  const ItemDescriptionSection({required this.item, super.key});

  final ItemDetail item;

  @override
  State<ItemDescriptionSection> createState() => _ItemDescriptionSectionState();
}

class _ItemDescriptionSectionState extends State<ItemDescriptionSection> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemDetailViewModel>();
    final sellerProfile = vm.sellerProfile;
    final bids = vm.bidHistory;

    final String avatarUrl = (sellerProfile?['profile_image_url'] as String?) ?? '';
    final String rawNickname =
        (sellerProfile?['nick_name'] as String?)?.trim() ?? '';
    final String sellerNickname =
        rawNickname.isNotEmpty ? rawNickname : '닉네임 없음';
    final double sellerRating =
        (sellerProfile?['rating'] as num?)?.toDouble() ?? widget.item.sellerRating;
    final int sellerReviewCount =
        (sellerProfile?['review_count'] as int?) ?? widget.item.sellerReviewCount;

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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: BorderColor,
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isNotEmpty
                          ? null
                          : const Icon(Icons.person, color: BackgroundColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sellerNickname,
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
                                '${sellerRating.toStringAsFixed(1)} ($sellerReviewCount)',
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
                        if (widget.item.sellerId.isEmpty) return;
                        context.push('/user/${widget.item.sellerId}');
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
                  widget.item.itemContent,
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
                _buildBidHistoryList(bids),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBidHistoryList(List<BidHistoryItem> bids) {
    // 가격이 0원인 입찰은 표시하지 않음
    final filteredBids = bids.where((bid) => bid.price != 0).toList();

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
        final price = bid.price.toString();
        final createdAtRaw = bid.createdAt;
        final relative = formatRelativeTime(createdAtRaw);

        // 입찰 타입/상태 표시
        final int code = bid.auctionLogCode ?? 0;
        String typeLabel = '';
        String statusLabel = '';

        // 현재 정의된 로그 코드 기준
        // 410: 경매 진행 중(일반 입찰), 411: 상위 입찰, 430: 입찰 낙찰, 431: 즉시 구매 낙찰
        if (code == 431) {
          typeLabel = '즉시 입찰';
        } else if (code == 410 || code == 411 || code == 430) {
          typeLabel = '일반 입찰';
        } else if (price.isNotEmpty) {
          // 그 외 코드는 가격이 들어와 있으면 즉시 입찰 실패로 간주
          typeLabel = '즉시 입찰';
          statusLabel = '실패';
        }

        String trailingLabel = '';
        if (typeLabel.isNotEmpty && statusLabel.isNotEmpty) {
          trailingLabel = ' ($typeLabel · $statusLabel)';
        } else if (typeLabel.isNotEmpty) {
          trailingLabel = ' ($typeLabel)';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${index + 1}. $price원$trailingLabel',
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
  }
}
