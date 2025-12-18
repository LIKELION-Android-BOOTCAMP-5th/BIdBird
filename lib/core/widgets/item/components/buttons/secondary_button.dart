import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 공통 Secondary 버튼 (파란색 테두리, 파란색 텍스트)
/// 매물 등록, 신고 화면의 "이전" 버튼 등에서 사용
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 48,
    this.fontSize = 13,
    this.width,
  });

  /// 버튼 텍스트
  final String text;

  /// 버튼 클릭 콜백
  final VoidCallback? onPressed;

  /// 버튼 높이
  final double height;

  /// 텍스트 폰트 크기
  final double fontSize;

  /// 버튼 너비 (null이면 double.infinity)
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: blueColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: blueColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

