import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/formatters/price_formatter.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:bidbird/core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 거래 내역 카드 컴포넌트
class TradeHistoryCard extends StatelessWidget {
  const TradeHistoryCard({
    super.key,
    required this.title,
    required this.thumbnailUrl,
    required this.status,
    required this.price,
    required this.itemId,
    required this.isSeller,
    this.actionType,
    this.isHighlighted = false,
    this.bottomSlot,
    this.useResponsive = false,
  });

  final String title;
  final String? thumbnailUrl;
  final String status;
  final int price;
  final String itemId;
  final bool isSeller;
  final TradeActionType? actionType;
  final bool isHighlighted;
  final Widget? bottomSlot;
  final bool useResponsive;

  @override
  Widget build(BuildContext context) {
    // 역할 색상 결정
    final roleColor = isSeller ? roleSalePrimary : rolePurchasePrimary;
    final cardPaddingValue =
        useResponsive ? ResponsiveConstants.screenPadding(context) : 14.0;
    final thumbnailSize =
        useResponsive ? context.widthRatio(0.16, min: 64.0, max: 80.0) : 64.0;
    final mediaSpacing =
        useResponsive ? ResponsiveConstants.spacingSmall(context) : 12.0;
    final tagFontSize = useResponsive
        ? ResponsiveConstants.fontSizeSmall(context)
        : 11.0;
    final tagSpacing =
        useResponsive ? ResponsiveConstants.spacingSmall(context) * 0.5 : 6.0;
    final rowSpacing =
        useResponsive ? ResponsiveConstants.spacingSmall(context) : 8.0;
    final badgePadding =
        useResponsive ? ResponsiveConstants.spacingSmall(context) * 0.8 : 10.0;
    final badgeFontSize = useResponsive
        ? ResponsiveConstants.fontSizeSmall(context)
        : 12.0;
    final priceFontSize = useResponsive
        ? ResponsiveConstants.fontSizeMedium(context)
        : 13.0;
    final titleFontSize = useResponsive
        ? ResponsiveConstants.fontSizeMedium(context)
        : 15.0;

    // 단순한 고정 값 사용으로 레이아웃 오류 방지
    const adaptivePadding = 10.8;
    const adaptiveSpacing = 12.0;
    const adaptiveThumbnail = 60.0;
    
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: defaultBorder,
            border: Border.all(
              color: BorderColor.withValues(alpha: 0.25),
              width: isHighlighted ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: shadowHigh,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: shadowLow,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(defaultRadius),
                    bottomLeft: Radius.circular(defaultRadius),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      GestureDetector(
                        onTap: () async {
                          if (itemId.isEmpty) return;
                          if (isSeller && status == '경매 대기') {
                            await _navigateToRegistrationDetail(context);
                          } else {
                            context.push('/item/$itemId');
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FixedRatioThumbnail(
                              imageUrl: thumbnailUrl,
                              width: adaptiveThumbnail,
                              height: adaptiveThumbnail,
                              aspectRatio: 1.0,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            SizedBox(width: adaptiveSpacing),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      RoleBadge(
                                        isSeller: isSeller,
                                        fontSize: tagFontSize,
                                      ),
                                      SizedBox(width: tagSpacing),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: rowSpacing),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: badgePadding,
                                          vertical: badgePadding * 0.4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getTradeStatusColor(status)
                                              .withValues(alpha: 0.1),
                                          borderRadius: defaultBorder,
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: getTradeStatusColor(status),
                                            fontSize: badgeFontSize,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        formatPrice(price),
                                        style: TextStyle(
                                          fontSize: priceFontSize,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bottomSlot != null) bottomSlot!,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Future<void> _navigateToRegistrationDetail(BuildContext context) async {
    try {
      final supabase = SupabaseManager.shared.supabase;
      // items_detail에서 필요한 정보 가져오기
      final result = await supabase
          .from('items_detail')
          .select(
              'start_price, auction_duration_hours, thumbnail_image, description')
          .eq('item_id', itemId)
          .single();

      if (result == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매물 정보를 불러올 수 없습니다.')),
        );
        return;
      }

      final startPrice = getIntFromRow(result, 'start_price');
      final auctionDurationHours =
          getIntFromRow(result, 'auction_duration_hours', 24);
      final thumbnailUrl = getNullableStringFromRow(result, 'thumbnail_image');
      // final buyNowPrice = getIntFromRow(result, 'buy_now_price', 0);
      final description = getStringFromRow(result, 'description');

      // ItemRegistrationData 생성
      final registrationData = ItemRegistrationData(
        id: itemId,
        title: title,
        description: description,
        startPrice: startPrice,
        // instantPrice: buyNowPrice,
        instantPrice: 0, // 기본값으로 0 설정
        auctionDurationHours: auctionDurationHours,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        statusText: '승인 완료',
      );

      if (!context.mounted) return;
      await context.push(
        '/add_item/item_registration_detail',
        extra: registrationData,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')),
      );
    }
  }

  // 가격 포맷은 공용 포맷터 사용으로 이동
}

