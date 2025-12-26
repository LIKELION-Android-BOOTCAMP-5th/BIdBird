import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:flutter/material.dart';

/// 입찰 가격 스테퍼 섹션
/// 
/// 입찰 금액을 증가/감소할 수 있는 스테퍼 UI
class BidPriceStepperSection extends StatelessWidget {
  final int bidAmount;
  final String bidUnitLabel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool canDecrease;
  final bool canIncrease;
  final double amountFontSize;

  const BidPriceStepperSection({
    super.key,
    required this.bidAmount,
    required this.bidUnitLabel,
    required this.onIncrease,
    required this.onDecrease,
    required this.canDecrease,
    required this.canIncrease,
    required this.amountFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(defaultRadius),
        border: Border.all(color: const Color(0xFFD7E3FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '입찰 금액',
            style: TextStyle(
              fontSize: 13,
              color: blueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.remove,
                onPressed: canDecrease ? onDecrease : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${formatPrice(bidAmount)}원',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.w800,
                        color: blueColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StepperButton(
                icon: Icons.add,
                onPressed: canIncrease ? onIncrease : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isEnabled ? const Color(0xFFD7E3FF) : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isEnabled ? textColor : Colors.grey.shade500,
        ),
      ),
    );
  }
}
