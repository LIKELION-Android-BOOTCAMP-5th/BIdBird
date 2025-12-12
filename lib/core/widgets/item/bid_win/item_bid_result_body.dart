import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';

class ItemBidResultBody extends StatelessWidget {
  const ItemBidResultBody({
    super.key,
    required this.item,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.actions,
    this.onClose,
  });

  final ItemBidWinEntity item;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Widget> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        SizedBox(height: 8),
        Icon(
          icon,
          size: 72,
          color: iconColor,
        ),
        SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: iconColor,
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: defaultBorder,
              boxShadow: [
                BoxShadow(
                  color: shadowHigh,
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ImageBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(defaultRadius),
                        topRight: Radius.circular(defaultRadius),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: item.images.isNotEmpty
                        ? Builder(
                            builder: (context) {
                              final imageUrl = item.images.first;
                              if (imageUrl.isEmpty) {
                                return Container(
                                  color: ImageBackgroundColor,
                                  child: Center(
                                    child: Text(
                                      '이미지 없음',
                                      style: TextStyle(color: iconColor),
                                    ),
                                  ),
                                );
                              }
                              
                              final bool isVideo = isVideoFile(imageUrl);
                              final String displayUrl = isVideo
                                  ? getVideoThumbnailUrl(imageUrl)
                                  : imageUrl;
                              
                              return displayUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: displayUrl,
                                      cacheManager: ItemImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: ImageBackgroundColor,
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        // 에러 발생 시 원본 URL로 재시도 (비디오가 아닌 경우)
                                        if (!isVideo && imageUrl.isNotEmpty && imageUrl != displayUrl) {
                                          return CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            cacheManager: ItemImageCacheManager.instance,
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => Container(
                                              color: ImageBackgroundColor,
                                              child: Center(
                                                child: Text(
                                                  '이미지 없음',
                                                  style: TextStyle(color: iconColor),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Container(
                                          color: ImageBackgroundColor,
                                          child: Center(
                                            child: Text(
                                              '이미지 없음',
                                              style: TextStyle(color: iconColor),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: ImageBackgroundColor,
                                      child: Center(
                                        child: Text(
                                          '이미지 없음',
                                          style: TextStyle(color: iconColor),
                                        ),
                                      ),
                                    );
                            },
                          )
                        : Center(
                            child: Text(
                              '상품 이미지',
                              style: TextStyle(color: iconColor),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '낙찰가',
                        style: TextStyle(
                          fontSize: 12,
                          color: iconColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${formatPrice(item.winPrice)}원',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: actions,
          ),
        ),
      ],
    );
  }
}