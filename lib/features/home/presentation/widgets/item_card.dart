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
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      FixedRatioThumbnail(
                        imageUrl: item.thumbnail_image,
                        aspectRatio: 1.0,
                        borderRadius: BorderRadius.circular(defaultRadius),
                      ),

                      Positioned(
                        top: 8,
                        right: 8,
                        child: HomeTimerSection(finishTime: item.finishTime),
                      ),

                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(defaultRadius),
                              bottomRight: Radius.circular(defaultRadius),
                            ),
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Colors.black87],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Text(
                          "${item.auctions.current_price.toCommaString()}원",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${item.auctions.bid_count}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (DateTime.now().isAfter(item.finishTime))
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius:
                              BorderRadius.circular(defaultRadius),
                            ),
                            child: const Center(
                              child: Text(
                                "종료된 상품입니다",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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