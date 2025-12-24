import 'package:bidbird/core/utils/formatters/price_formatter.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import 'package:flutter/material.dart';

/// 여매 매물 등록 카드 컴포넌트
/// - 가격, 경매기간, 제목 표시
/// - 좌측 띠지는 파란색으로 통일
class AuctionItemCard extends StatelessWidget {
  const AuctionItemCard({
    super.key,
    required this.title,
    required this.thumbnailUrl,
    required this.price,
    required this.auctionDurationHours,
    this.onTap,
    this.useResponsive = true,
  });

  final String title;
  final String? thumbnailUrl;
  final int price;
  final int auctionDurationHours;
  final VoidCallback? onTap;
  final bool useResponsive;

  String get _auctionDurationText {
    if (auctionDurationHours >= 24) {
      final days = auctionDurationHours ~/ 24;
      final hours = auctionDurationHours % 24;
      if (hours == 0) {
        return '${days}일';
      }
      return '${days}일 ${hours}시간';
    }
    return '${auctionDurationHours}시간';
  }

  @override
  Widget build(BuildContext context) {
    const blueBarColor = Color(0xFF4A5FFF); // 파란색으로 통일
    final double barWidth = useResponsive
      ? context.widthRatio(0.012, min: 3.0, max: 5.0)
      : 4.0;
    final double contentPadding = useResponsive
      ? context.spacingSmall + 6.0
      : 16.0;
    final double contentPaddingVertical = useResponsive
      ? context.spacingSmall
      : 12.0;
    final double thumbnailSize = useResponsive
      ? context.widthRatio(0.16, min: 52.0, max: 70.0)
      : 56.0;
    final double gapBetweenMediaAndText = useResponsive
      ? context.spacingSmall + 2.0
      : 12.0;
    final double metaSpacing = useResponsive
      ? context.spacingSmall * 0.6
      : 6.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: chatItemCardBackground,
          borderRadius: defaultBorder,
          border: Border.all(
            color: BorderColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(color: shadowHigh, blurRadius: 10, offset: Offset(0, 4)),
            BoxShadow(color: shadowLow, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측 파란색 띠지
              Container(
                width: barWidth,
                decoration: BoxDecoration(
                  color: blueBarColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(defaultRadius),
                    bottomLeft: Radius.circular(defaultRadius),
                  ),
                ),
              ),
              // 메인 콘텐츠
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: contentPadding,
                    vertical: contentPaddingVertical,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 썸네일
                      FixedRatioThumbnail(
                        imageUrl: thumbnailUrl,
                        width: thumbnailSize,
                        height: thumbnailSize,
                        aspectRatio: 1.0,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      SizedBox(width: gapBetweenMediaAndText),
                      // 정보 영역
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: useResponsive
                                    ? context.fontSizeLarge + 2
                                    : 18,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: metaSpacing * 0.6 + 11),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAuctionDurationRow(
                                    context,
                                    fontSize: useResponsive
                                        ? context.fontSizeMedium
                                        : 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatPrice(price),
                                  style: TextStyle(
                                    fontSize: useResponsive
                                        ? context.fontSizeMedium
                                        : 13,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 경매 기간을 아이콘 + 텍스트로 표현
  Widget _buildAuctionDurationRow(BuildContext context, {double? fontSize}) {
    final double resolvedFontSize = fontSize ??
        (useResponsive ? context.fontSizeMedium : 13);
    final double iconSize = useResponsive
        ? context.iconSizeSmall * 0.65
        : 14;

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: iconSize,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '경매 $_auctionDurationText',
            style: TextStyle(
              fontSize: resolvedFontSize,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
