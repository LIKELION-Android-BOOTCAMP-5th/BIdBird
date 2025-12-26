import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:flutter/material.dart';

/// 입찰 정보 요약 카드
/// 
/// 현재가와 호가를 표시하는 카드 위젯
class BidInfoSummaryCard extends StatelessWidget {
  final int currentPrice;
  final String bidUnitLabel;

  const BidInfoSummaryCard({
    super.key,
    required this.currentPrice,
    required this.bidUnitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: defaultBorder,
        boxShadow: [
          BoxShadow(
            color: shadowLow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재가',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatPrice(currentPrice)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '호가',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bidUnitLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: blueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
