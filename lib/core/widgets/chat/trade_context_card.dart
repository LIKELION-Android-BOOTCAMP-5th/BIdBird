import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/chat/trade_action_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    this.onCardTap,
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
  final VoidCallback? onCardTap;
  final VoidCallback? onTradeComplete;
  final VoidCallback? onTradeCancel;

  /// 거래 상태에 따른 배경색 반환
  Color _getTradeStatusBackgroundColor() {
    if (tradeStatusCode == null) {
      return const Color(0xFFE9ECEF); // 기본 중립색
    }

    switch (tradeStatusCode) {
      case 510: // 결제 대기
        return const Color(0xFFE9ECEF); // 중립색
      case 520: // 거래 중
        return const Color(0xFFE9ECEF); // 중립색
      case 550: // 거래 완료
        return const Color(0xFFE6F4EA); // 성공색 배경
      default:
        return const Color(0xFFE9ECEF); // 기본 중립색
    }
  }

  /// 거래 상태에 따른 텍스트 색상 반환
  Color _getTradeStatusTextColor() {
    if (tradeStatusCode == null) {
      return const Color(0xFF5F6368); // 기본 중립 텍스트
    }

    switch (tradeStatusCode) {
      case 510: // 결제 대기
        return const Color(0xFF5F6368); // 중립 텍스트
      case 520: // 거래 중
        return const Color(0xFF5F6368); // 중립 텍스트
      case 550: // 거래 완료
        return const Color(0xFF1E8E3E); // 성공 텍스트
      default:
        return const Color(0xFF5F6368); // 기본 중립 텍스트
    }
  }

  /// 거래 상태 텍스트 반환
  String _getTradeStatusText() {
    if (tradeStatusCode == null) {
      return tradeStatus;
    }

    switch (tradeStatusCode) {
      case 510:
        return '결제 대기';
      case 520:
        return '거래 중';
      case 550:
        return '거래 완료';
      default:
        return tradeStatus;
    }
  }

  /// 거래 액션 표시 여부 (오버플로 메뉴)
  /// 배송 정보가 입력되었을 때만 표시
  bool _shouldShowOverflowMenu() {
    if (tradeStatusCode == null) return false;
    
    // 거래 완료 상태에서는 액션 메뉴 숨김
    if (tradeStatusCode == 550) return false;
    
    // 배송 정보가 입력되었을 때만 표시
    if (!hasShippingInfo) return false;
    
    return onTradeComplete != null || onTradeCancel != null;
  }

  @override
  Widget build(BuildContext context) {
    final statusBackgroundColor = _getTradeStatusBackgroundColor();
    final statusTextColor = _getTradeStatusTextColor();
    final statusText = _getTradeStatusText();
    final showOverflowMenu = _shouldShowOverflowMenu();

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
        child: InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일 (48x48)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ImageBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: itemThumbnail != null && itemThumbnail!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: itemThumbnail!,
                                cacheManager: ItemImageCacheManager.instance,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: ImageBackgroundColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: ImageBackgroundColor,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: BorderColor,
                                    size: 24,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                color: BorderColor,
                                size: 24,
                              ),
                      ),
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
                    // 우측 액션 영역 (분리된 터치 영역)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 거래 관리 버튼 (텍스트) - 거래 액션
                        if (showOverflowMenu)
                          TextButton(
                            onPressed: () {
                              TradeActionBottomSheet.show(
                                context,
                                onTradeComplete: onTradeComplete ?? () {},
                                onTradeCancel: onTradeCancel,
                                isTradeCompleted: tradeStatusCode == 550,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '거래 관리',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8), // 액션 색상
                              ),
                            ),
                          ),
                        // 매물 상세 보기 (거래 관리 하단)
                        if (showOverflowMenu)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Text(
                              '매물 상세 보기',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8A8D91), // 보조 링크 색상
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

