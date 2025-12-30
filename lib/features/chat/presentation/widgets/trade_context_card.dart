import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import 'package:flutter/material.dart';

/// 거래 컨텍스트 카드 컴포넌트
/// 채팅 화면 상단에 표시되는 거래 정보 및 액션 카드
class TradeContextCard extends StatelessWidget {
  const TradeContextCard({
    super.key,
    required this.itemTitle,
    required this.itemThumbnail,
    required this.itemPrice,
    required this.isSeller,
    required this.tradeStatus,
    required this.tradeStatusCode,
    required this.hasShippingInfo,
    this.onItemTap,
    this.onTradeStatusTap,
    this.onTradeResultTap,
  });

  final String itemTitle;
  final String? itemThumbnail;
  final int itemPrice;
  final bool isSeller;
  final String tradeStatus;
  final int? tradeStatusCode;
  final bool hasShippingInfo;
  final VoidCallback? onItemTap;
  final VoidCallback? onTradeStatusTap;
  final VoidCallback? onTradeResultTap; // 거래 결과 버튼 콜백

  /// 거래 액션 버튼 표시 여부 (하단 버튼 제거로 인해 항상 false 또는 로직 삭제)
  bool get _shouldShowTradeActions => false; // 하단 버튼 제거

  @override
  Widget build(BuildContext context) {
    return Container(
      // ... existing decoration ...
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE1E4E8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 매물 정보 영역 (클릭 가능)
            InkWell(
              onTap: onItemTap,
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 썸네일 (48x48)
                    FixedRatioThumbnail(
                      imageUrl: itemThumbnail,
                      width: 48,
                      height: 48,
                      aspectRatio: null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    // 정보 영역
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1행: 매물명
                          Text(
                            itemTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111111),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // 2행: 가격
                          if (itemPrice != 0)
                            Text(
                              "${formatPrice(itemPrice)}원",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 우측 액션 영역
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 거래 결과 버튼 (낙찰자용)
                        if (onTradeResultTap != null)
                          GestureDetector(
                            onTap: () {},
                            child: TextButton(
                              onPressed: onTradeResultTap,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '거래 결과',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: blueColor,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: blueColor,
                                  ),
                                ],
                              ),
                            ),
                          )
                        // 거래 현황 보기 / 거래 평가 버튼 (기존)
                        else if (onTradeStatusTap != null)
                          GestureDetector(
                            onTap: () {},
                            child: TextButton(
                              onPressed: onTradeStatusTap,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tradeStatusCode == 550
                                        ? '거래 평가'
                                        : '거래 현황 보기',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: blueColor,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: blueColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
