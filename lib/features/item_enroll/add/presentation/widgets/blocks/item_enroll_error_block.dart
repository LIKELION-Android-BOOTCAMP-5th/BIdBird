import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemEnrollErrorBlock extends StatelessWidget {
  const ItemEnrollErrorBlock({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: RedColor, size: context.iconSizeMedium),
          SizedBox(height: context.spacingMedium),
          Text(
            message,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: RedColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacingMedium),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: rolePurchasePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('다시 시도', style: TextStyle(color: chatItemCardBackground)),
          ),
        ],
      ),
    );
  }
}
