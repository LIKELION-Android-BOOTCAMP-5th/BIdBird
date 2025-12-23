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

  // 오버플로 감지를 위한 키 + 캐시 상태
  final GlobalKey _textKey = GlobalKey();
  bool _needsExpansion = false;
  bool _overflowCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleOverflowCheck();
  }

  @override
  void didUpdateWidget(covariant ItemDetailDescriptionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.itemContent != widget.item.itemContent) {
      _scheduleOverflowCheck();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 폰트 스케일/미디어쿼리 변화 시에도 재측정
    _scheduleOverflowCheck();
  }

  void _scheduleOverflowCheck() {
    if (_isExpanded || _overflowCheckScheduled) return;
    _overflowCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 현재 가용 폭 계산 (build와 동일 계산식 유지)
      final horizontalPadding = context.screenPadding;
      final maxContentWidth =
          MediaQuery.of(context).size.width - (horizontalPadding * 2);

      // build에서 사용한 텍스트 스타일과 동일하게 측정
      final bodyFontSize = context.fontSizeSmall;
      final baseTextStyle = TextStyle(
        fontSize: bodyFontSize,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7684),
      );

      final description = widget.item.itemContent;
      final textPainter = TextPainter(
        text: TextSpan(text: description, style: baseTextStyle),
        maxLines: _collapsedMaxLines,
        textDirection: Directionality.of(context),
        ellipsis: '…',
      )..layout(minWidth: 0, maxWidth: maxContentWidth);

      final hasOverflow = textPainter.didExceedMaxLines;
      if (mounted && hasOverflow != _needsExpansion) {
        setState(() {
          _needsExpansion = hasOverflow;
        });
      }

      _overflowCheckScheduled = false;
    });
  }

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

    // 텍스트 스타일(재사용해 할당/GC 부담 감소)
    final baseTextStyle = TextStyle(
      fontSize: bodyFontSize,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF6B7684),
    );

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
            RichText(
              key: _textKey,
              text: TextSpan(text: description, style: baseTextStyle),
              maxLines: _isExpanded ? null : _collapsedMaxLines,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              softWrap: true,
            ),
            if (_needsExpansion) ...[
              SizedBox(height: spacingSmall * 0.8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                  if (!_isExpanded) {
                    _scheduleOverflowCheck();
                  }
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
