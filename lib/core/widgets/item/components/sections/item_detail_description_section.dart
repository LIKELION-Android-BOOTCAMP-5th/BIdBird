import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:flutter/material.dart';

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

    // Section Container - padding 24 (좌우), 상단 여백 최소화
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Line
          const Text(
            '상품 설명',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF191F28), // Primary Text
            ),
          ),
          const SizedBox(height: 12),
          // Body Text
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7684), // Secondary Text
            ),
            maxLines: _isExpanded ? null : _maxLines,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (needsExpansion) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? '접기' : '더 보기',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9CA3AF), // Tertiary
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

}

