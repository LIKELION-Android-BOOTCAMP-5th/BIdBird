import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/category_bottom_sheet.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';
import 'package:flutter/material.dart';

/// 카테고리 선택 필드 위젯
/// 로딩 상태와 선택 상태를 처리하는 카테고리 선택 UI
class CategorySelectorField extends StatelessWidget {
  const CategorySelectorField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.isLoading,
    this.hasError = false,
    this.onErrorCleared,
    this.categoryKey,
  });

  /// 카테고리 목록 (id와 title 속성을 가진 객체 리스트)
  final List<dynamic> categories;

  /// 선택된 카테고리 ID
  final int? selectedCategoryId;

  /// 카테고리 선택 콜백
  final ValueChanged<int> onCategorySelected;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 상태
  final bool hasError;

  /// 에러 제거 콜백 (선택 사항)
  final VoidCallback? onErrorCleared;

  final GlobalKey? categoryKey;

  String _getSelectedCategoryTitle() {
    if (selectedCategoryId == null) {
      return '카테고리 선택';
    }
    try {
      if (categories.isEmpty) {
        return '카테고리 선택';
      }

      KeywordTypeEntity? foundCategory;
      for (final category in categories) {
        if (category is KeywordTypeEntity &&
            category.id == selectedCategoryId) {
          foundCategory = category;
          break;
        }
      }

      if (foundCategory == null) {
        return '카테고리 선택';
      }

      return foundCategory.title;
    } catch (e) {
      return '카테고리 선택';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputPadding = context.inputPadding;
    final iconSizeSmall = context.iconSizeSmall;
    final fontSizeSmall = context.fontSizeSmall;

    if (isLoading) {
      return Container(
        key: categoryKey,
        height: 48,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: inputPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(defaultRadius),
          border: Border.all(color: hasError ? RedColor : BackgroundColor),
        ),
        child: SizedBox(
          height: iconSizeSmall,
          width: iconSizeSmall,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (categories.isEmpty) {
          return;
        }
        CategoryBottomSheet.show(
          context,
          categories: categories.cast<KeywordTypeEntity>(),
          selectedCategoryId: selectedCategoryId,
          onCategorySelected: (id) {
            onCategorySelected(id);
            onErrorCleared?.call();
          },
        );
      },
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: inputPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(defaultRadius),
          border: Border.all(
            color: hasError
                ? RedColor
                : selectedCategoryId != null
                ? blueColor
                : BackgroundColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _getSelectedCategoryTitle(),
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    color: selectedCategoryId != null ? textColor : iconColor,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: selectedCategoryId != null ? blueColor : iconColor,
            ),
          ],
        ),
      ),
    );
  }
}
