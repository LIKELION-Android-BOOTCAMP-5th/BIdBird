import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.decoration,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final InputDecoration? decoration;
  final bool required;

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
          decoration: decoration,
        ),
      ],
    );
  }
}
