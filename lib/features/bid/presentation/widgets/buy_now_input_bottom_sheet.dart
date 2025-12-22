import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bidbird/features/bid/presentation/viewmodels/buy_now_input_viewmodel.dart';

class BuyNowInputBottomSheet extends StatelessWidget {
  const BuyNowInputBottomSheet({
    super.key,
    required this.itemId,
    required this.buyNowPrice,
  });

  final String itemId;
  final int buyNowPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('즉시 구매: ${buyNowPrice}원'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement buy now logic
              Navigator.pop(context);
            },
            child: const Text('구매하기'),
          ),
        ],
      ),
    );
  }
}
