import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:flutter/material.dart';

/// 매물 등록 및 신고 화면에서 공통으로 사용하는 라벨이 있는 텍스트 필드
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.decoration,
    this.required = false,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final InputDecoration? decoration;
  final bool required;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final labelFontSize = context.fontSizeMedium;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.labelBottomPadding),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: RedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '필수',
                    style: TextStyle(
                      fontSize: context.fontSizeSmall * 0.85,
                      color: RedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: decoration ??
              createStandardInputDecoration(
                context,
                hint: hintText ?? '',
                errorText: errorText,
                fillColor: enabled ? Colors.white : BorderColor.withValues(alpha: 0.2),
              ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
