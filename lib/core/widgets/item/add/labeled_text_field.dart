import 'package:bidbird/core/utils/ui_set/colors_style.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
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
