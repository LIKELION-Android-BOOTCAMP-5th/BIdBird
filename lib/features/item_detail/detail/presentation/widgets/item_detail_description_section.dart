import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemDetailDescriptionSection extends StatelessWidget {
  const ItemDetailDescriptionSection({required this.item, super.key});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    final description = item.itemContent;

    final horizontalPadding = context.screenPadding;
    final bodyFontSize = context.fontSizeMedium;

    // 텍스트 스타일
    final baseTextStyle = TextStyle(
      fontSize: bodyFontSize,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF6B7684),
    );

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Text(
        description,
        style: baseTextStyle,
      ),
    );
  }
}
