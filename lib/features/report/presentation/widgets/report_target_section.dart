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
    const Color borderGray = LightBorderColor;
    const Color textPrimary = TextPrimary;
    // const Color textDisabled = chatTimeTextColor; // 미사용
    const Color backgroundGray = chatItemSectionBackground;

    final labelFontSize = context.fontSizeMedium;
    final spacing = context.spacingMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 신고 대상 섹션
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: context.labelBottomPadding),
              child: Row(
                children: [
                  Text(
                    '신고 대상',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              padding: EdgeInsets.symmetric(
                horizontal: context.inputPadding,
              ),
              decoration: BoxDecoration(
                color: backgroundGray,
                borderRadius: BorderRadius.circular(defaultRadius),
                border: Border.all(
                  color: borderGray,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        targetNickname ?? '알 수 없음',
                        style: TextStyle(
                          fontSize: context.fontSizeSmall,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 신고 글 섹션
        if (itemId != null && itemTitle != null) ...[
          SizedBox(height: spacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                child: Row(
                  children: [
                    Text(
                      '신고 글',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 48,
                padding: EdgeInsets.symmetric(
                  horizontal: context.inputPadding,
                ),
                decoration: BoxDecoration(
                  color: backgroundGray,
                  borderRadius: BorderRadius.circular(defaultRadius),
                  border: Border.all(
                    color: borderGray,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          itemTitle!,
                          style: TextStyle(
                            fontSize: context.fontSizeSmall,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}



