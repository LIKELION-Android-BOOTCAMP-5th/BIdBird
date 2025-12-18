import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

/// 공통 에러 메시지 텍스트 위젯
/// 폼 검증 에러를 일관되게 표시
class ErrorText extends StatelessWidget {
  const ErrorText({
    super.key,
    required this.text,
    this.topPadding,
  });

  /// 에러 메시지 텍스트
  final String text;

  /// 상단 패딩 (기본값: spacingSmall)
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding ?? context.spacingSmall,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fontSizeSmall,
          color: RedColor,
        ),
      ),
    );
  }
}



