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

  String _getSelectedCategoryTitle() {
    debugPrint('[CategorySelectorField] _getSelectedCategoryTitle 호출 - selectedCategoryId: $selectedCategoryId, categories.length: ${categories.length}');
    if (selectedCategoryId == null) {
      debugPrint('[CategorySelectorField] selectedCategoryId가 null - "카테고리 선택" 반환');
      return '카테고리 선택';
    }
    try {
      if (categories.isEmpty) {
        debugPrint('[CategorySelectorField] categories가 비어있음 - "카테고리 선택" 반환');
        return '카테고리 선택';
      }
      
      KeywordTypeEntity? foundCategory;
      for (final category in categories) {
        if (category is KeywordTypeEntity && category.id == selectedCategoryId) {
          foundCategory = category;
          break;
        }
      }
      
      if (foundCategory == null) {
        debugPrint('[CategorySelectorField] 카테고리를 찾을 수 없음 (id: $selectedCategoryId) - "카테고리 선택" 반환');
        return '카테고리 선택';
      }
      
      debugPrint('[CategorySelectorField] 선택된 카테고리: ${foundCategory.title}');
      return foundCategory.title;
    } catch (e) {
      debugPrint('[CategorySelectorField] 에러 발생: $e - "카테고리 선택" 반환');
      return '카테고리 선택';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 48,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(
          horizontal: context.inputPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(defaultRadius),
          border: Border.all(
            color: hasError ? RedColor : BackgroundColor,
          ),
        ),
        child: SizedBox(
          height: context.iconSizeSmall,
          width: context.iconSizeSmall,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        debugPrint('[CategorySelectorField] 필드 탭됨');
        debugPrint('[CategorySelectorField] categories.length: ${categories.length}');
        debugPrint('[CategorySelectorField] selectedCategoryId: $selectedCategoryId');
        debugPrint('[CategorySelectorField] isLoading: $isLoading');
        if (categories.isEmpty) {
          debugPrint('[CategorySelectorField] categories가 비어있음 - 바텀시트 열지 않음');
          return;
        }
        debugPrint('[CategorySelectorField] 바텀시트 열기 시작');
        CategoryBottomSheet.show(
          context,
          categories: categories.cast<KeywordTypeEntity>(),
          selectedCategoryId: selectedCategoryId,
          onCategorySelected: (id) {
            debugPrint('[CategorySelectorField] onCategorySelected 콜백 받음: id=$id');
            onCategorySelected(id);
            debugPrint('[CategorySelectorField] onCategorySelected(id) 호출 완료');
            onErrorCleared?.call();
            debugPrint('[CategorySelectorField] onErrorCleared 호출 완료');
          },
        );
        debugPrint('[CategorySelectorField] CategoryBottomSheet.show 호출 완료');
      },
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: context.inputPadding,
        ),
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
                    fontSize: context.fontSizeSmall,
                    color: selectedCategoryId != null
                        ? textColor
                        : iconColor,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: selectedCategoryId != null
                  ? blueColor
                  : iconColor,
            ),
          ],
        ),
      ),
    );
  }
}

