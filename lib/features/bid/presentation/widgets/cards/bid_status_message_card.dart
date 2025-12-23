import 'package:flutter/material.dart';

/// 입찰 상태 메시지 카드
class BidStatusMessageCard extends StatelessWidget {
  final bool isValid;
  final String statusText;

  const BidStatusMessageCard({
    super.key,
    required this.isValid,
    required this.statusText,
  });

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
