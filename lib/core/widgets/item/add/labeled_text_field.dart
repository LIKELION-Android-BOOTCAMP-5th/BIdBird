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
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final labelFontSize = context.fontSizeMedium;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.labelBottomPadding),
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
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
