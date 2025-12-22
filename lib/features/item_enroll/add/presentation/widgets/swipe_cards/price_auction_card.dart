import 'package:bidbird/core/mixins/form_validation_mixin.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/category_selector_field.dart';
import 'package:bidbird/core/widgets/item/components/fields/duration_chip_selector.dart';
import 'package:bidbird/core/widgets/item/components/fields/error_text.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label_with_checkbox.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_error_messages.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 카드 2: 가격·경매
class PriceAuctionCard extends StatefulWidget {
  const PriceAuctionCard({
    super.key,
    required this.viewModel,
    required this.inputDecoration,
  });

  final ItemAddViewModel viewModel;
  final InputDecoration Function(String hint) inputDecoration;

  @override
  State<PriceAuctionCard> createState() => PriceAuctionCardState();
}

class PriceAuctionCardState extends State<PriceAuctionCard>
    with FormValidationMixin {
  String? _startPriceError;
  String? _instantPriceError;
  String? _categoryError;
  String? _durationError;
  bool _shouldShowErrors = false;

  @override
  bool get shouldShowErrors => _shouldShowErrors;

  @override
  set shouldShowErrors(bool value) => _shouldShowErrors = value;

  void validatePrices() {
    startValidation(() {
      final startPrice = parseFormattedPrice(
        widget.viewModel.startPriceController.text,
      );
      final instantPrice = widget.viewModel.useInstantPrice
          ? parseFormattedPrice(widget.viewModel.instantPriceController.text)
          : null;

      if (startPrice <= 0) {
        _startPriceError =
            ItemRegistrationErrorMessages.startPriceInvalidNumber;
      } else if (startPrice < ItemPriceLimits.minPrice) {
        _startPriceError = ItemRegistrationErrorMessages.startPriceRange(
          ItemPriceLimits.minPrice,
          ItemPriceLimits.maxPrice,
        );
      }

      if (widget.viewModel.useInstantPrice) {
        if (instantPrice == null || instantPrice <= 0) {
          _instantPriceError =
              ItemRegistrationErrorMessages.instantPriceInvalidNumber;
        } else if (instantPrice < ItemPriceLimits.minPrice) {
          _instantPriceError = ItemRegistrationErrorMessages.instantPriceRange(
            ItemPriceLimits.minPrice,
            ItemPriceLimits.maxPrice,
          );
        } else if (instantPrice <= startPrice) {
          _instantPriceError =
              ItemRegistrationErrorMessages.instantPriceMustBeHigher;
        }
      }

      if (widget.viewModel.selectedDuration == null) {
        _durationError = ItemRegistrationErrorMessages.auctionDurationRequired;
      }

      if (widget.viewModel.selectedKeywordTypeId == null) {
        _categoryError = ItemRegistrationErrorMessages.categoryRequired;
      }
    });
  }

  @override
  void clearAllErrors() {
    _startPriceError = null;
    _instantPriceError = null;
    _categoryError = null;
    _durationError = null;
  }

  void _handlePriceInput(
    String value,
    TextEditingController controller,
    ValueChanged<int>? onValidated,
  ) {
    final formatted = formatNumber(value);
    if (formatted != value) {
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // 검증 콜백이 있으면 실행
    if (onValidated != null) {
      final price = parseFormattedPrice(formatted);
      onValidated(price);
    }
    // notifyListeners 제거: item_add_screen에서 직접 체크하므로 불필요
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingMedium;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: context.hPadding,
        vertical: context.vPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시작가 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormLabel(text: '시작가 (원)'),
              TextField(
                controller: widget.viewModel.startPriceController,
                keyboardType: TextInputType.number,
                decoration: widget
                    .inputDecoration('시작 가격 입력')
                    .copyWith(
                      errorText: shouldShowErrors ? _startPriceError : null,
                    ),
                onChanged: (value) {
                  _handlePriceInput(
                    value,
                    widget.viewModel.startPriceController,
                    shouldShowErrors && _startPriceError != null
                        ? (startPrice) {
                            if (startPrice > 0 &&
                                startPrice >= ItemPriceLimits.minPrice) {
                              clearError(() => _startPriceError = null);
                            }
                          }
                        : null,
                  );
                },
              ),
            ],
          ),
          // SizedBox(height: spacing),
          // // 즉시 구매가 체크박스
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     FormLabelWithCheckbox(
          //       text: '즉시 구매가 (원)',
          //       value: widget.viewModel.useInstantPrice,
          //       onChanged: (value) {
          //         widget.viewModel.setUseInstantPrice(value);
          //         // 체크박스 변경 시에는 검증하지 않음
          //       },
          //     ),
          //     // 즉시 구매가 입력 (항상 표시, 체크박스로 활성화/비활성화)
          //     TextField(
          //       controller: widget.viewModel.instantPriceController,
          //       keyboardType: TextInputType.number,
          //       enabled: widget.viewModel.useInstantPrice,
          //       decoration: widget
          //           .inputDecoration('즉시 구매가 입력')
          //           .copyWith(
          //             errorText: shouldShowErrors ? _instantPriceError : null,
          //             fillColor: widget.viewModel.useInstantPrice
          //                 ? Colors.white
          //                 : BorderColor.withValues(alpha: 0.2),
          //           ),
          //       onChanged: (value) {
          //         _handlePriceInput(
          //           value,
          //           widget.viewModel.instantPriceController,
          //           shouldShowErrors && _instantPriceError != null
          //               ? (instantPrice) {
          //                   final startPrice = parseFormattedPrice(
          //                     widget.viewModel.startPriceController.text,
          //                   );
          //                   if (instantPrice >= ItemPriceLimits.minPrice &&
          //                       instantPrice > startPrice) {
          //                     clearError(() => _instantPriceError = null);
          //                   }
          //                 }
          //               : null,
          //         );
          //       },
          //     ),
          //   ],
          // ),
          SizedBox(height: spacing),
          // 경매 기간 선택
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormLabel(text: '경매 기간'),
              DurationChipSelector(
                durations: widget.viewModel.durations,
                selectedDuration: widget.viewModel.selectedDuration,
                onDurationSelected: (duration) {
                  widget.viewModel.setSelectedDuration(duration);
                },
                onErrorCleared: shouldShowErrors && _durationError != null
                    ? () => clearError(() => _durationError = null)
                    : null,
              ),
              if (shouldShowErrors && _durationError != null)
                ErrorText(text: _durationError!),
            ],
          ),
          SizedBox(height: spacing),
          // 카테고리 선택
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormLabel(text: '카테고리'),
              Selector<
                ItemAddViewModel,
                ({
                  List<KeywordTypeEntity> keywordTypes,
                  int? selectedKeywordTypeId,
                  bool isLoadingKeywords,
                })
              >(
                selector: (_, vm) => (
                  keywordTypes: vm.keywordTypes,
                  selectedKeywordTypeId: vm.selectedKeywordTypeId,
                  isLoadingKeywords: vm.isLoadingKeywords,
                ),
                builder: (context, data, _) {
                  return CategorySelectorField(
                    categories: data.keywordTypes,
                    selectedCategoryId: data.selectedKeywordTypeId,
                    onCategorySelected: (id) {
                      widget.viewModel.setSelectedKeywordTypeId(id);
                    },
                    isLoading: data.isLoadingKeywords,
                    hasError: shouldShowErrors && _categoryError != null,
                    onErrorCleared: shouldShowErrors && _categoryError != null
                        ? () => clearError(() => _categoryError = null)
                        : null,
                  );
                },
              ),
              if (shouldShowErrors && _categoryError != null)
                ErrorText(text: _categoryError!),
            ],
          ),
        ],
      ),
    );
  }
}
