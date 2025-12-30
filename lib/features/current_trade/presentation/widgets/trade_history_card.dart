import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
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
/// 성능 최적화: RepaintBoundary로 감싸서 독립적인 리페인트 가능
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
    this.isTopBidder = false,
    this.isOpponentTopBidder = false,
    this.isExpired = false,
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
  final bool isTopBidder;
  final bool isOpponentTopBidder;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    // 역할 색상 결정
    final roleColor = isSeller ? roleSalePrimary : rolePurchasePrimary;
    // 성능 최적화: 반응형 값들을 한 번에 계산
    final cardPadding = useResponsive
        ? ResponsiveConstants.spacingMedium(context) * 0.65
        : 7.0;
    final thumbnailSize = useResponsive
        ? context.widthRatio(0.18, min: 50.0, max: 65.0)
        : 50.0;
    final gapBetweenMediaAndText = useResponsive
        ? ResponsiveConstants.spacingSmall(context) * 0.8
        : 10.0;
    final tagFontSize = useResponsive
        ? ResponsiveConstants.fontSizeSmall(context)
        : 11.0;
    final tagSpacing = useResponsive
        ? ResponsiveConstants.spacingSmall(context) * 0.5
        : 6.0;
    final rowSpacing = useResponsive
        ? ResponsiveConstants.spacingSmall(context)
        : 8.0;
    final priceFontSize = useResponsive
        ? ResponsiveConstants.fontSizeMedium(context) + 3.0
        : 16.0;
    final titleFontSize = useResponsive
        ? ResponsiveConstants.fontSizeMedium(context)
        : 15.0;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: chatItemCardBackground,
          borderRadius: defaultBorder,
          border: Border.all(
            color: BorderColor.withValues(alpha: 0.25),
            width: isHighlighted ? 1.5 : 1,
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
              Container(
                width: 4,
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
                  padding: EdgeInsets.all(cardPadding),
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
                          // 요청: 썸네일과 텍스트 컬럼을 세로 기준 가운데 정렬
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FixedRatioThumbnail(
                              imageUrl: thumbnailUrl,
                              width: thumbnailSize,
                              height: thumbnailSize,
                              aspectRatio: 1.0,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            SizedBox(width: gapBetweenMediaAndText),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      RoleBadge(
                                        isSeller: isSeller,
                                        isTopBidder: isTopBidder,
                                        isOpponentTopBidder: isOpponentTopBidder,
                                        isExpired: isExpired,
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
                                    children: [
                                      // 배지 바로 아래 정렬 (들여쓰기 제거)
                                      Text(
                                        formatPrice(price),
                                        style: TextStyle(
                                          fontSize: priceFontSize,
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
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
            'start_price, auction_duration_hours, thumbnail_image, description',
          )
          .eq('item_id', itemId)
          .single();

      // Supabase .single()가 실패시 예외로 처리되므로 null 체크는 불필요

      final startPrice = getIntFromRow(result, 'start_price');
      final auctionDurationHours = getIntFromRow(
        result,
        'auction_duration_hours',
        24,
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')));
    }
  }

  // 가격 포맷은 공용 포맷터 사용으로 이동
}
