import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemDetailDescriptionSection extends StatefulWidget {
  const ItemDetailDescriptionSection({required this.item, super.key});

  final ItemDetail item;

  @override
  State<ItemDetailDescriptionSection> createState() => _ItemDetailDescriptionSectionState();
}

class _ItemDetailDescriptionSectionState extends State<ItemDetailDescriptionSection> {
  bool _isExpanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final description = widget.item.itemContent;
    final needsExpansion = description.length > 100; // 간단한 기준, 실제로는 TextPainter로 계산 가능

    final horizontalPadding = context.screenPadding;
    final titleFontSize = context.fontSizeMedium;
    final bodyFontSize = context.fontSizeSmall;
    final spacingSmall = context.spacingSmall;
    final spacingMedium = context.spacingMedium;
    final isCompact = context.isSmallScreen(threshold: 360);
    final translateY = isCompact ? -30.0 : -40.0;

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, spacingSmall, horizontalPadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상품 설명',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF191F28),
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              description,
              style: TextStyle(
                fontSize: bodyFontSize,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7684),
              ),
              maxLines: _isExpanded ? null : _maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (needsExpansion) ...[
              SizedBox(height: spacingSmall * 0.8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? '접기' : '더 보기',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: const Color(0xFF9CA3AF),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
            SizedBox(height: spacingMedium),
          ],
        ),
      ),
    );
  }
}
