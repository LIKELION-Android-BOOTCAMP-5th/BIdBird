import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:flutter/material.dart';

/// 재사용 가능한 하단 고정 제출 버튼 컴포넌트
/// 신고하기와 매물 등록에서 공통으로 사용
class BottomSubmitButton extends StatelessWidget {
  const BottomSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.height,
  });

  /// 버튼 텍스트
  final String text;

  /// 버튼 클릭 콜백
  final VoidCallback? onPressed;

  /// 버튼 활성화 여부
  final bool isEnabled;

  /// 버튼 높이
  final double? height;

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color textDisabled = Color(0xFF9CA3AF);
    const Color buttonDisabledBg = Color(0xFFE5E7EB);

    final buttonHeight = height ?? 40;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          disabledBackgroundColor: buttonDisabledBg,
          foregroundColor: Colors.white,
          disabledForegroundColor: textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
