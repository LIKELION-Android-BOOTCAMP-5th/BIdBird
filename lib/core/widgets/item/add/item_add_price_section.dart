import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/features/item/add/viewmodel/item_add_viewmodel.dart';

class ItemAddPriceSection extends StatelessWidget {
  const ItemAddPriceSection({
    super.key,
    required this.viewModel,
    required this.inputDecoration,
  });

  final ItemAddViewModel viewModel;
  final InputDecoration Function(String hint) inputDecoration;

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final labelFontSize = context.fontSizeMedium;
    final spacing = context.inputPadding;
    
    final startPriceField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.labelBottomPadding),
          child: Text(
            '시작가 (원)',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        TextField(
          controller: viewModel.startPriceController,
          keyboardType: TextInputType.number,
          decoration: inputDecoration('시작 가격 입력'),
          onChanged: (value) {
            final formatted = formatNumber(value);
            if (formatted != value) {
              viewModel.startPriceController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(
                  offset: formatted.length,
                ),
              );
            }
          },
        ),
      ],
    );
    
    final instantPriceField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.spacingSmall * 0.5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '즉시 입찰가 (원)',
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Checkbox(
                value: viewModel.useInstantPrice,
                activeColor: blueColor,
                checkColor: Colors.white,
                side: BorderSide(
                  color: viewModel.useInstantPrice
                      ? blueColor
                      : Colors.black,
                ),
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (value) {
                  if (value == null) return;
                  viewModel.setUseInstantPrice(value);
                },
              ),
            ],
          ),
        ),
        TextField(
          controller: viewModel.instantPriceController,
          keyboardType: TextInputType.number,
          enabled: viewModel.useInstantPrice,
          decoration: inputDecoration('즉시 입찰가 입력').copyWith(
            fillColor: viewModel.useInstantPrice
                ? Colors.white
                : BorderColor.withValues(alpha: 0.2),
          ),
          onChanged: (value) {
            final formatted = formatNumber(value);
            if (formatted != value) {
              viewModel.instantPriceController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(
                  offset: formatted.length,
                ),
              );
            }
          },
        ),
      ],
    );
    
    if (context.isSmallScreen()) {
      return Column(
        children: [
          startPriceField,
          SizedBox(height: spacing),
          instantPriceField,
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: startPriceField),
        SizedBox(width: spacing),
        Expanded(child: instantPriceField),
      ],
    );
  }
}
