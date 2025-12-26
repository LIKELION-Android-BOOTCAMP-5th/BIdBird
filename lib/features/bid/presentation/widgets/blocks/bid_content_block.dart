import 'package:flutter/material.dart';

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

class BidContentBlock extends StatelessWidget {
  const BidContentBlock({
    super.key,
    required this.displayCurrentPrice,
    required this.bidUnitLabel,
    required this.statusMessage,
    required this.isValidStatus,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onClose,
    required this.onSubmit,
    required this.buildBidStepper,
    required this.quickPresetRow,
  });

  final int displayCurrentPrice;
  final String bidUnitLabel;
  final String statusMessage;
  final bool isValidStatus;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback? onSubmit;
  final Widget Function() buildBidStepper;
  final Widget quickPresetRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '입찰하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BidInfoSummary(
          currentPrice: displayCurrentPrice,
          bidUnitLabel: bidUnitLabel,
        ),
        const SizedBox(height: 20),
        buildBidStepper(),
        const SizedBox(height: 12),
        quickPresetRow,
        const SizedBox(height: 16),
        _BidStatusMessage(
          isValid: isValidStatus,
          statusText: statusMessage,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '입찰하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _BidInfoSummary extends StatelessWidget {
  const _BidInfoSummary({
    required this.currentPrice,
    required this.bidUnitLabel,
  });

  final int currentPrice;
  final String bidUnitLabel;

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
                      '${_formatPrice(currentPrice)}원',
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

class _BidStatusMessage extends StatelessWidget {
  const _BidStatusMessage({
    required this.isValid,
    required this.statusText,
  });

  final bool isValid;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final color = isValid ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatPrice(int price) {
  final s = price.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final pos = s.length - i;
    buf.write(s[i]);
    if (pos > 1 && pos % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
