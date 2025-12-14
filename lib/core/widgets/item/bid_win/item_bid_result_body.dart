import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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
    this.priceLabel,
  });

  final ItemBidWinEntity item;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final String? priceLabel;

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final iconSize = context.widthRatio(0.18, min: 56.0, max: 88.0); // 특수 케이스: 큰 아이콘
    final titleFontSize = context.fontSizeXLarge;
    final subtitleFontSize = context.fontSizeSmall;
    final itemTitleFontSize = context.buttonFontSize;
    final priceLabelFontSize = context.fontSizeSmall;
    final priceFontSize = context.fontSizeLarge;
    final horizontalPadding = context.screenPadding;
    final verticalPadding = context.spacingMedium;
    final spacing = context.spacingMedium;
    final smallSpacing = context.spacingSmall;
    
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        SizedBox(height: smallSpacing),
        Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
        SizedBox(height: spacing),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: smallSpacing),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: iconColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: subtitleFontSize,
                                      ),
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
                                                  style: TextStyle(
                                                    color: iconColor,
                                                    fontSize: subtitleFontSize,
                                                  ),
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
                                              style: TextStyle(
                                                color: iconColor,
                                                fontSize: subtitleFontSize,
                                              ),
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
                                          style: TextStyle(
                                            color: iconColor,
                                            fontSize: subtitleFontSize,
                                          ),
                                        ),
                                      ),
                                    );
                            },
                          )
                        : Center(
                            child: Text(
                              '상품 이미지',
                              style: TextStyle(
                                color: iconColor,
                                fontSize: subtitleFontSize,
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    context.heightRatio(0.017, min: 12.0, max: 18.0), // 특수 케이스: 내부 패딩
                    horizontalPadding,
                    horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: itemTitleFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: smallSpacing * 0.6),
                      Text(
                        priceLabel ?? '낙찰가',
                        style: TextStyle(
                          fontSize: priceLabelFontSize,
                          color: iconColor,
                        ),
                      ),
                      SizedBox(height: smallSpacing * 0.2),
                      Text(
                        '${formatPrice(item.winPrice)}원',
                        style: TextStyle(
                          fontSize: priceFontSize,
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
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            verticalPadding,
          ),
          child: Column(
            children: actions,
          ),
        ),
      ],
    );
  }
}