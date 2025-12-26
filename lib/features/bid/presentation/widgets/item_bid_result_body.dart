import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';

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
    final iconSize = context.widthRatio(0.18, min: 56.0, max: 88.0);
    final titleFontSize = context.fontSizeXLarge;
    final subtitleFontSize = context.fontSizeSmall;
    final itemTitleFontSize = context.buttonFontSize;
    final priceLabelFontSize = context.fontSizeSmall;
    final priceFontSize = context.fontSizeLarge;
    final horizontalPadding = context.screenPadding;
    final verticalPadding = context.spacingMedium;
    final spacing = context.spacingMedium;
    final smallSpacing = context.spacingSmall;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 700;
        final contentPadding = isCompact ? horizontalPadding * 0.8 : horizontalPadding;
        final contentSpacing = isCompact ? spacing * 0.75 : spacing;
        final thumbnailAspect = isCompact ? 4 / 3 : 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ),
            SizedBox(height: smallSpacing),
            Icon(icon, size: iconSize, color: iconColor),
            SizedBox(height: contentSpacing),
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
            SizedBox(height: contentSpacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: contentPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: isCompact ? 280 : 320,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chatItemCardBackground,
                    borderRadius: defaultBorder,
                    boxShadow: [
                      BoxShadow(
                        color: shadowHigh,
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FixedRatioThumbnail(
                        imageUrl: item.images.isNotEmpty && item.images.first.isNotEmpty
                            ? item.images.first
                            : null,
                        aspectRatio: thumbnailAspect,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(defaultRadius),
                          topRight: Radius.circular(defaultRadius),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding,
                          smallSpacing,
                          contentPadding,
                          contentPadding,
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
            ),
            SizedBox(height: contentSpacing),
            Padding(
              padding: EdgeInsets.fromLTRB(
                contentPadding,
                0,
                contentPadding,
                verticalPadding,
              ),
              child: Column(children: actions),
            ),
          ],
        );
      },
    );
  }
}

