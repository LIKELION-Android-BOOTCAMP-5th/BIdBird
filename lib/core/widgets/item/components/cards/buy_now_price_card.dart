import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class BuyNowPriceCard extends StatelessWidget {
  const BuyNowPriceCard({super.key, required this.formattedPrice});

  final String formattedPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: defaultBorder,
        boxShadow: [
          BoxShadow(
            color: shadowLow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: defaultBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '즉시 구매가',
              style: TextStyle(fontSize: 13, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              formattedPrice,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: blueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
