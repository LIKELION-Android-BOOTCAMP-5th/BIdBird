import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemDetailDescriptionSection extends StatefulWidget {
  const ItemDetailDescriptionSection({required this.item, super.key});

  final ItemDetail item;

  @override
  State<ItemDetailDescriptionSection> createState() =>
      _ItemDetailDescriptionSectionState();
}

class _ItemDetailDescriptionSectionState
    extends State<ItemDetailDescriptionSection> {
  bool _isExpanded = false;
  static const int _collapsedMaxLines = 1; // 접기 상태에서 1줄만 보여줌

  @override
  Widget build(BuildContext context) {
    final description = widget.item.itemContent;

    final horizontalPadding = context.screenPadding;
    final titleFontSize = context.fontSizeMedium;
    final bodyFontSize = context.fontSizeSmall;
    final spacingSmall = context.spacingSmall;
    final spacingMedium = context.spacingMedium;
    final isCompact = context.isSmallScreen(threshold: 360);
    final translateY = isCompact ? -30.0 : -40.0;

    // 화면에 그려질 실제 가용 폭 계산
    final maxContentWidth =
        MediaQuery.of(context).size.width - (horizontalPadding * 2);

    // 텍스트가 1줄을 초과하는지 정확히 계산
    final baseTextStyle = TextStyle(
      fontSize: bodyFontSize,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF6B7684),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: description, style: baseTextStyle),
      maxLines: _collapsedMaxLines,
      textDirection: Directionality.of(context),
      ellipsis: '…',
    )..layout(minWidth: 0, maxWidth: maxContentWidth);

    final needsExpansion = textPainter.didExceedMaxLines;

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          spacingSmall,
          horizontalPadding,
          0,
        ),
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
              style: baseTextStyle,
              maxLines: _isExpanded ? null : _collapsedMaxLines,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
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
