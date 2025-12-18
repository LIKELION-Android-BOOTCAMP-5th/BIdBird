import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 공통 Primary 버튼 (파란색 배경, 흰색 텍스트)
/// 매물 등록, 신고, 상세 화면 등에서 사용
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.height = 48,
    this.fontSize = 13,
    this.width,
  });

  /// 버튼 텍스트
  final String text;

  /// 버튼 클릭 콜백
  final VoidCallback? onPressed;

  /// 버튼 활성화 여부
  final bool isEnabled;

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
      child: ElevatedButton(
        onPressed: isEnabled && onPressed != null ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isEnabled ? blueColor : BorderColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BorderColor,
          disabledForegroundColor: iconColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

