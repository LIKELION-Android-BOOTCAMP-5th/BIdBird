import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:bidbird/features/item/current_trade/model/current_trade_entity.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    this.onActionButtonPressed,
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
  final Widget? Function()? onActionButtonPressed;
  final bool useResponsive;

  @override
  Widget build(BuildContext context) {
    // 역할 색상 결정
    final roleColor = isSeller ? roleSalePrimary : rolePurchasePrimary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: defaultBorder,
        border: Border.all(
          color: BorderColor.withValues(alpha: 0.25),
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: blueColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측 역할 인디케이터 스트립
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
            // 메인 컨텐츠
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (itemId.isEmpty) return;

                      // 경매 대기 상태이고 판매자인 경우 매물 등록 최종 화면으로 이동
                      if (isSeller && status == '경매 대기') {
                        await _navigateToRegistrationDetail(context);
                      } else {
                        context.push('/item/$itemId');
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final cardPadding = useResponsive
                            ? EdgeInsets.all(ResponsiveConstants.screenPadding(context))
                            : const EdgeInsets.all(14);
                        return Padding(
                          padding: cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 썸네일
                                  Builder(
                                    builder: (context) {
                                      final thumbnailSize = useResponsive
                                          ? context.widthRatio(0.16, min: 64.0, max: 80.0)
                                          : 64.0;
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: thumbnailSize,
                                          height: thumbnailSize,
                                          color: BackgroundColor,
                                          child: thumbnailUrl != null &&
                                                  thumbnailUrl!.isNotEmpty
                                              ? Builder(
                                                  builder: (context) {
                                                    final bool isVideo =
                                                        isVideoFile(thumbnailUrl!);
                                                    final String displayUrl = isVideo
                                                        ? getVideoThumbnailUrl(
                                                            thumbnailUrl!)
                                                        : thumbnailUrl!;

                                                    return CachedNetworkImage(
                                                      imageUrl: displayUrl,
                                                      cacheManager:
                                                          ItemImageCacheManager
                                                              .instance,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        color: BackgroundColor,
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget:
                                                          (context, url, error) =>
                                                              Container(
                                                        color: BackgroundColor,
                                                        child: const Icon(
                                                          Icons.image_outlined,
                                                          color: BorderColor,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Icon(
                                                  Icons.image_outlined,
                                                  color: BorderColor,
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final spacing = useResponsive
                                          ? ResponsiveConstants.spacingSmall(
                                              context)
                                          : 12.0;
                                      return SizedBox(width: spacing);
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 역할 태그와 제목
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // 역할 태그
                                            Builder(
                                              builder: (context) {
                                                final tagFontSize = useResponsive
                                                    ? ResponsiveConstants
                                                        .fontSizeSmall(context)
                                                    : 11.0;
                                                return RoleBadge(
                                                  isSeller: isSeller,
                                                  fontSize: tagFontSize,
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final spacing = useResponsive
                                                    ? ResponsiveConstants
                                                            .spacingSmall(
                                                        context) *
                                                        0.5
                                                    : 6.0;
                                                return SizedBox(width: spacing);
                                              },
                                            ),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  final titleFontSize =
                                                      useResponsive
                                                          ? ResponsiveConstants
                                                              .fontSizeMedium(
                                                                  context)
                                                          : 15.0;
                                                  return Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: titleFontSize,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final spacing = useResponsive
                                                ? ResponsiveConstants
                                                    .spacingSmall(context)
                                                : 8.0;
                                            return SizedBox(height: spacing);
                                          },
                                        ),
                                        // 상태 배지와 가격
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final badgePadding =
                                                    useResponsive
                                                        ? ResponsiveConstants
                                                                .spacingSmall(
                                                            context) *
                                                            0.8
                                                        : 10.0;
                                                final badgeFontSize =
                                                    useResponsive
                                                        ? ResponsiveConstants
                                                            .fontSizeSmall(
                                                                context)
                                                        : 12.0;
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: badgePadding,
                                                    vertical: badgePadding * 0.4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: getTradeStatusColor(
                                                            status)
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        defaultBorder,
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      color: getTradeStatusColor(
                                                          status),
                                                      fontSize: badgeFontSize,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final priceFontSize =
                                                    useResponsive
                                                        ? ResponsiveConstants
                                                            .fontSizeMedium(
                                                                context)
                                                        : 13.0;
                                                return Text(
                                                  _formatMoney(price),
                                                  style: TextStyle(
                                                    fontSize: priceFontSize,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // 하단 액션 버튼 (있는 경우)
                  if (onActionButtonPressed != null)
                    onActionButtonPressed!() ?? const SizedBox.shrink(),
                ],
              ),
            ),
          ],
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
              'start_price, auction_duration_hours, thumbnail_image, buy_now_price, description')
          .eq('item_id', itemId)
          .maybeSingle();

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
      final buyNowPrice = getIntFromRow(result, 'buy_now_price');
      final description = getStringFromRow(result, 'description');

      // ItemRegistrationData 생성
      final registrationData = ItemRegistrationData(
        id: itemId,
        title: title,
        description: description,
        startPrice: startPrice,
        instantPrice: buyNowPrice,
        auctionDurationHours: auctionDurationHours,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
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

  String _formatMoney(int value) {
    final s = value.toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$formatted원';
  }
}

