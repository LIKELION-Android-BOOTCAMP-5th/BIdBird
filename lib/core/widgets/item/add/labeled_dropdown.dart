import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.decoration,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final labelFontSize = context.fontSizeMedium;
    final itemFontSize = context.fontSizeSmall;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
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
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: decoration,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: items.isEmpty 
                ? const Color(0xFF9CA3AF) 
                : const Color(0xFF6B7280),
          ),
          dropdownColor: Colors.white,
          style: TextStyle(
            fontSize: itemFontSize,
            color: items.isEmpty 
                ? const Color(0xFF9CA3AF) 
                : const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}
