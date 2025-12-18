import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/spacing_ratios.dart';
import 'package:flutter/material.dart';

/// 공통 폼 라벨 위젯
/// 매물 등록, 신고 화면 등에서 사용하는 일관된 라벨 스타일
class FormLabel extends StatelessWidget {
  const FormLabel({
    super.key,
    required this.text,
    this.required = false,
  });

  /// 라벨 텍스트
  final String text;

  /// 필수 여부 표시
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.labelBottomPadding),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (required) ...[
            SizedBox(width: UISizes.labelBadgeSpacing),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: UISizes.requiredBadgeHorizontalPadding,
                vertical: UISizes.requiredBadgeVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: RedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(UISizes.requiredBadgeBorderRadius),
              ),
              child: Text(
                '필수',
                style: TextStyle(
                  fontSize: context.fontSizeSmall * SpacingRatios.smallFontSize,
                  color: RedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

