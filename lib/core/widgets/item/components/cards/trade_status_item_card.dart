import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
import 'package:flutter/material.dart';

/// 거래 현황 아이템 카드 컴포넌트
/// 거래 현황 화면과 거래 내역 화면에서 사용하는 아이템 카드
class TradeStatusItemCard extends StatelessWidget {
  const TradeStatusItemCard({
    super.key,
    required this.title,
    required this.price,
    required this.thumbnailUrl,
    required this.roleText,
    required this.statusText,
    this.onTap,
  });

  final String title;
  final int price;
  final String? thumbnailUrl;
  final String roleText; // "구매자" 또는 "판매자"
  final String statusText; // "입찰 중", "결제 대기" 등
  final VoidCallback? onTap;

  /// 역할에 따른 색상 결정
  bool get _isSeller => roleText == '판매자';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 좌측 띠지
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _isSeller
                        ? roleSalePrimary
                        : rolePurchasePrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // 태그 영역
                    if (roleText.isNotEmpty || statusText.isNotEmpty)
                      Row(
                        children: [
                          if (roleText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isSeller
                                    ? roleSaleSub
                                    : rolePurchaseSub,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isSeller
                                      ? roleSaleText
                                      : rolePurchaseText,
                                ),
                              ),
                            ),
                          if (roleText.isNotEmpty && statusText.isNotEmpty)
                            const SizedBox(width: 8),
                          if (statusText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: blueColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: blueColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (roleText.isNotEmpty || statusText.isNotEmpty)
                      const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatPrice(price)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: blueColor,
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 썸네일
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                child: FixedRatioThumbnail(
                  imageUrl: thumbnailUrl,
                  width: 80,
                  height: 80,
                  aspectRatio: 1.0,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

