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
    this.onTradeComplete,
    this.onTradeCancel,
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
  final VoidCallback? onTradeComplete;
  final VoidCallback? onTradeCancel;

  /// 거래 액션 버튼 표시 여부
  bool get _shouldShowTradeActions {
    if (tradeStatusCode == null) return false;
    if (tradeStatusCode == 550) return false; // 거래 완료 상태에서는 숨김
    if (tradeStatusCode == 540) return false; // 이미 취소된 거래에서는 숨김
    return onTradeComplete != null || onTradeCancel != null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA), // 거래 컨텍스트 카드 배경
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE1E4E8), // 카드 하단 divider
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
                      aspectRatio: null, // 원본 비율 유지
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
                              fontWeight: FontWeight.w500, // Medium
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
                                fontWeight: FontWeight.w700, // Bold
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
                        // 거래 현황 보기 / 거래 평가 버튼
                        if (onTradeStatusTap != null)
                          GestureDetector(
                            onTap: () {
                              // 버튼 탭 이벤트가 카드 탭 이벤트로 전파되지 않도록
                            },
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
                                    // 거래 완료 상태(550)일 때는 "거래 평가", 그 외에는 "거래 현황 보기"
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
            // 거래 관리 버튼 영역 (카드 내부에 포함)
            if (_shouldShowTradeActions)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTradeCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: RedColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '거래 취소',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: RedColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTradeComplete,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: blueColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '거래 완료',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
