import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabel(
          text: label,
          required: required,
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
