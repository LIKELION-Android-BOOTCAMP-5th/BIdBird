import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:flutter/material.dart';

class ReportTargetSection extends StatelessWidget {
  const ReportTargetSection({
    super.key,
    this.itemId,
    this.itemTitle,
    this.targetNickname,
  });

  final String? itemId;
  final String? itemTitle;
  final String? targetNickname;

  @override
  Widget build(BuildContext context) {
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textPrimary = Color(0xFF111111);
    const Color textSecondary = Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: defaultBorder,
        border: Border.all(
          color: borderGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '신고 대상',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (itemId != null) ...[
            Text(
              itemTitle ?? '알 수 없음',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            targetNickname ?? '알 수 없음',
            style: const TextStyle(
              fontSize: 13,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

