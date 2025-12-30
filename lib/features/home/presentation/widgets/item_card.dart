import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/extension/money_extension.dart';
import '../../../../core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import '../../domain/entities/items_entity.dart';
import '../viewmodel/home_viewmodel.dart';
import 'home_timer_section.dart';

class ItemCard extends StatelessWidget {
  final ItemsEntity item;
  final String title;
  final GlobalKey? currentPriceKey;
  final GlobalKey? biddingCountKey;
  final GlobalKey? finishTimeKey;

  const ItemCard({
    super.key,
    required this.item,
    required this.title,
    this.currentPriceKey,
    this.biddingCountKey,
    this.finishTimeKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          final homeVm = context.read<HomeViewmodel>();
          // 검색 모드일 경우 검색 모드 종료 (자동 꺼짐)
          if (homeVm.searchButton) {
            homeVm.workSearchBar();
          }
          context.push('/item/${item.item_id}');
        },
        child: Column(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      FixedRatioThumbnail(
                        imageUrl: item.thumbnail_image,
                        aspectRatio: 1.25,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),

                      if (!DateTime.now().isAfter(item.finishTime))
                        Positioned(
                          key: finishTimeKey,
                          top: 6,
                          right: 6,
                          child: HomeTimerSection(finishTime: item.finishTime),
                        ),

                      if (DateTime.now().isAfter(item.finishTime))
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.4), // 시각적 무게 조절
                            child: Center(
                              child: Text(
                                "종료된 상품",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // 정보 영역 고정 높이 느낌으로 압축
                  Padding(
                    padding: const EdgeInsets.all(8.0), // 내부 패딩 8px
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              key: currentPriceKey,
                              child: Text(
                                "${item.auctions.current_price.toCommaString()}원",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D1B20),
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              key: biddingCountKey,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Color(0xFF79747E),
                                  size: 13,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "${item.auctions.bid_count}",
                                  style: const TextStyle(
                                    color: Color(0xFF79747E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 3), // 간격 압축
                        Text(
                          title,
                          maxLines: 1, // 1줄 제한
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF49454F),
                            fontWeight: FontWeight.normal,
                            height: 1.1,
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
      ),
    );
  }
}
