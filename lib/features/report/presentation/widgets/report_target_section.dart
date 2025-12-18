import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.inputPadding,
          vertical: context.inputPadding,
        ),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(defaultRadius),
          border: Border.all(
            color: borderGray,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemId != null && itemTitle != null) ...[
              Text(
                '신고 글: ${itemTitle!}',
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.spacingSmall * 0.5),
            ],
            Text(
              '신고 대상: ${targetNickname ?? '알 수 없음'}',
              style: TextStyle(
                fontSize: context.fontSizeSmall,
                color: textPrimary,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}



