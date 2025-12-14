import 'package:bidbird/features/report/model/report_type_entity.dart';
import 'package:flutter/material.dart';

class ReportCategoryBottomSheet extends StatelessWidget {
  const ReportCategoryBottomSheet({
    super.key,
    required this.categories,
    required this.allReportTypes,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final List<ReportTypeEntity> allReportTypes;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  String _getCategoryName(String category) {
    try {
      final firstType = allReportTypes.firstWhere(
        (e) => e.category == category,
      );
      return firstType.categoryName;
    } catch (e) {
      return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // 카테고리 항목들
          ...categories.map((category) {
            final categoryName = _getCategoryName(category);
            final isSelected = selectedCategory == category;
            
            return _ReportCategoryItem(
              label: categoryName,
              isSelected: isSelected,
              onTap: () {
                Navigator.of(context).pop();
                onCategorySelected(category);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 바텀 시트를 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required List<String> categories,
    required List<ReportTypeEntity> allReportTypes,
    String? selectedCategory,
    required ValueChanged<String> onCategorySelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => ReportCategoryBottomSheet(
        categories: categories,
        allReportTypes: allReportTypes,
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }
}

class _ReportCategoryItem extends StatefulWidget {
  const _ReportCategoryItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ReportCategoryItem> createState() => _ReportCategoryItemState();
}

class _ReportCategoryItemState extends State<_ReportCategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: widget.isSelected 
          ? const Color(0xFFF3F4F6) 
          : const Color(0xFFFAFAFB),
      end: const Color(0xFFF3F4F6),
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_ReportCategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      _colorAnimation = ColorTween(
        begin: widget.isSelected 
            ? const Color(0xFFF3F4F6) 
            : const Color(0xFFFAFAFB),
        end: const Color(0xFFF3F4F6),
      ).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            height: 56,
            padding: const EdgeInsets.only(left: 20),
            color: widget.isSelected 
                ? const Color(0xFFF3F4F6) 
                : _colorAnimation.value,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111827),
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

