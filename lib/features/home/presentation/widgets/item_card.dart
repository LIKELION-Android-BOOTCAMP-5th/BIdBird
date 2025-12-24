import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extension/money_extension.dart';
import '../../../../core/utils/ui_set/border_radius_style.dart';
import '../../../../core/utils/ui_set/shadow_style.dart';
import '../../../../core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import '../../domain/entities/items_entity.dart';
import 'home_timer_section.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.title});

  final ItemsEntity item;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // item_detail 페이지로 이동
        context.push('/item/${item.item_id}');
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.7),
              boxShadow: [defaultShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      FixedRatioThumbnail(
                        imageUrl: item.thumbnail_image,
                        aspectRatio: 1.0,
                        borderRadius: BorderRadius.circular(defaultRadius),
                      ),

                      // 잔여 시간 (상세 화면과 동일 스타일)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: HomeTimerSection(finishTime: item.finishTime),
                      ),

                      // 입찰 건수
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                spacing: 3,
                                children: [
                                  Icon(
                                    Icons.account_circle,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  Text(
                                    "${item.auctions.bid_count}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      //현재 가격
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "${item.auctions.current_price.toCommaString()}원",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 시간 만료 되면 나오는 UI
                      if (DateTime.now().isAfter(item.finishTime))
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: defaultBorder,
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "종료된 상품입니다",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        title,
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
