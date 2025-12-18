import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

/// 체크박스가 있는 폼 라벨 위젯
/// 즉시 구매가 같은 선택 가능한 필드에 사용
class FormLabelWithCheckbox extends StatelessWidget {
  const FormLabelWithCheckbox({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  /// 라벨 텍스트
  final String text;

  /// 체크박스 값
  final bool value;

  /// 체크박스 변경 콜백
  final ValueChanged<bool> onChanged;

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
          const Spacer(),
          Checkbox(
            value: value,
            activeColor: blueColor,
            checkColor: Colors.white,
            side: BorderSide(
              color: value ? blueColor : BorderColor,
            ),
            visualDensity: const VisualDensity(
              horizontal: -4,
              vertical: -4,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
}



