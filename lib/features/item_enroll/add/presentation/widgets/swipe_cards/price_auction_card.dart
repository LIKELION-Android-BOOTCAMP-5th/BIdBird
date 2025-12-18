import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/auction_duration_bottom_sheet.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';

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

class PriceAuctionCardState extends State<PriceAuctionCard> {
  String? _startPriceError;
  String? _instantPriceError;
  bool _shouldShowErrors = false;

  void validatePrices() {
    setState(() {
      _shouldShowErrors = true;
      _startPriceError = null;
      _instantPriceError = null;

      final startPrice = parseFormattedPrice(widget.viewModel.startPriceController.text);
      final instantPrice = widget.viewModel.useInstantPrice
          ? parseFormattedPrice(widget.viewModel.instantPriceController.text)
          : null;

      if (startPrice <= 0) {
        _startPriceError = '시작가를 입력해주세요';
      } else if (startPrice < ItemPriceLimits.minPrice) {
        _startPriceError = '시작가는 ${ItemPriceLimits.minPrice ~/ 10000}만원 이상이어야 합니다';
      }

      if (widget.viewModel.useInstantPrice) {
        if (instantPrice == null || instantPrice <= 0) {
          _instantPriceError = '즉시 구매가를 입력해주세요';
        } else if (instantPrice < ItemPriceLimits.minPrice) {
          _instantPriceError = '즉시 구매가는 ${ItemPriceLimits.minPrice ~/ 10000}만원 이상이어야 합니다';
        } else if (instantPrice <= startPrice) {
          _instantPriceError = '즉시 구매가는 시작가보다 높아야 합니다';
        }
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _shouldShowErrors = false;
      _startPriceError = null;
      _instantPriceError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingMedium;
    final labelFontSize = context.fontSizeMedium;

    return SingleChildScrollView(
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
              Padding(
                padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                child: Row(
                  children: [
                    Text(
                      '시작가 (원)',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: widget.viewModel.startPriceController,
                keyboardType: TextInputType.number,
                decoration: widget.inputDecoration('시작 가격 입력').copyWith(
                  errorText: _shouldShowErrors ? _startPriceError : null,
                  errorMaxLines: 1,
                ),
                onChanged: (value) {
                  final formatted = formatNumber(value);
                  if (formatted != value) {
                    widget.viewModel.startPriceController.value =
                        TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  // 부모 위젯이 리빌드되어 physics가 업데이트되도록 함
                  widget.viewModel.notifyListeners();
                  // 입력 시 에러가 있으면 제거
                  if (_shouldShowErrors && _startPriceError != null) {
                    final startPrice = parseFormattedPrice(formatted);
                    if (startPrice >= ItemPriceLimits.minPrice) {
                      setState(() {
                        _startPriceError = null;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          SizedBox(height: spacing),
          // 즉시 구매가 체크박스
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                child: Row(
                  children: [
                    Text(
                      '즉시 구매가 (원)',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: widget.viewModel.useInstantPrice,
                      activeColor: blueColor,
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: widget.viewModel.useInstantPrice
                            ? blueColor
                            : BorderColor,
                      ),
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) {
                        if (value == null) return;
                        widget.viewModel.setUseInstantPrice(value);
                        // 체크박스 변경 시에는 검증하지 않음
                      },
                    ),
                  ],
                ),
              ),
              // 즉시 구매가 입력 (항상 표시, 체크박스로 활성화/비활성화)
              TextField(
                controller: widget.viewModel.instantPriceController,
                keyboardType: TextInputType.number,
                enabled: widget.viewModel.useInstantPrice,
                decoration: widget.inputDecoration('즉시 구매가 입력').copyWith(
                  errorText: _shouldShowErrors ? _instantPriceError : null,
                  errorMaxLines: 1,
                  fillColor: widget.viewModel.useInstantPrice
                      ? Colors.white
                      : BorderColor.withValues(alpha: 0.2),
                ),
                onChanged: (value) {
                  final formatted = formatNumber(value);
                  if (formatted != value) {
                    widget.viewModel.instantPriceController.value =
                        TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  // 부모 위젯이 리빌드되어 physics가 업데이트되도록 함
                  widget.viewModel.notifyListeners();
                  // 입력 시 에러가 있으면 제거
                  if (_shouldShowErrors && _instantPriceError != null) {
                    final instantPrice = parseFormattedPrice(formatted);
                    final startPrice = parseFormattedPrice(widget.viewModel.startPriceController.text);
                    if (instantPrice >= ItemPriceLimits.minPrice && instantPrice > startPrice) {
                      setState(() {
                        _instantPriceError = null;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          SizedBox(height: spacing),
          // 경매 기간 선택
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                child: Row(
                  children: [
                    Text(
                      '경매 기간',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              // 경매 기간 칩 UI - 4개씩 2줄로 배치
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final spacing = context.spacingSmall;
                  final chipWidth = (availableWidth - (spacing * 3)) / 4; // 4개 배치: 간격 3개
                  
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: widget.viewModel.durations.map((duration) {
                      final isSelected = widget.viewModel.selectedDuration == duration;
                      return SizedBox(
                        width: chipWidth,
                        child: GestureDetector(
                          onTap: () {
                            widget.viewModel.setSelectedDuration(duration);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.inputPadding,
                              vertical: context.spacingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? blueColor.withValues(alpha: 0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(defaultRadius),
                              border: Border.all(
                                color: isSelected ? blueColor : BackgroundColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              duration,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fontSizeSmall,
                                color: isSelected ? blueColor : textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}


