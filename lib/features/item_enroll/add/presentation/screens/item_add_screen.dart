import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart'
    show parseFormattedPrice;
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/components/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/item_add_viewmodel.dart';
import '../widgets/step_indicator.dart';
import '../widgets/swipe_cards/product_info_card.dart';
import '../widgets/swipe_cards/price_auction_card.dart';
import '../widgets/swipe_cards/detail_confirm_card.dart';

class ItemAddScreen extends StatefulWidget {
  const ItemAddScreen({super.key});

  @override
  State<ItemAddScreen> createState() => _ItemAddScreenState();
}

class _ItemAddScreenState extends State<ItemAddScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  static const List<String> _stepLabels = ['상품 정보', '가격·경매', '상세·확인'];

  // InputDecoration 캐시
  late final Map<String, InputDecoration> _decorationCache;

  InputDecoration _inputDecoration(String hint) {
    return _decorationCache.putIfAbsent(
      hint,
      () => createStandardInputDecoration(context, hint: hint),
    );
  }

  void _showImageSourceSheet(BuildContext context, ItemAddViewModel viewModel) {
    ImageSourceBottomSheet.show(
      context,
      onGalleryTap: () async {
        await viewModel.pickImagesFromGallery();
      },
      onCameraTap: () async {
        await viewModel.pickImageFromCamera();
      },
      onVideoTap: () async {
        await viewModel.pickVideoFromGallery();
      },
    );
  }

  void _goToStep(int step) {
    if (step >= 0 && step < 3) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canGoToNextStep(ItemAddViewModel viewModel) {
    switch (_currentStep) {
      case 0:
        // 카드 1: 이미지, 제목 필수
        return viewModel.selectedImages.isNotEmpty &&
            viewModel.titleController.text.trim().isNotEmpty;
      case 1:
        // 카드 2: 시작가, 경매기간, 카테고리 필수
        final startPrice = parseFormattedPrice(
          viewModel.startPriceController.text,
        );
        final hasValidStartPrice =
            startPrice > 0 && startPrice >= ItemPriceLimits.minPrice;
        final hasDuration = viewModel.selectedDuration != null;
        final hasCategory = viewModel.selectedKeywordTypeId != null;

        // 즉시 구매가가 체크되어 있으면 그것도 유효해야 함
        bool hasValidInstantPrice = true;
        // if (viewModel.useInstantPrice) {
        //   final instantPrice = parseFormattedPrice(viewModel.instantPriceController.text);
        //   hasValidInstantPrice = instantPrice > 0 &&
        //       instantPrice >= ItemPriceLimits.minPrice &&
        //       instantPrice > startPrice;
        // }

        return hasValidStartPrice &&
            hasDuration &&
            hasCategory &&
            hasValidInstantPrice;
      case 2:
        // 카드 3: 모든 검증 통과
        return viewModel.validate() == null;
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    return _currentStep == 2 ? '등록하기' : '다음';
  }

  void _handlePageChange(int index, ItemAddViewModel viewModel) {
    // 이전 페이지로 돌아가는 경우는 검증하지 않음
    if (index <= _currentStep) {
      setState(() {
        _currentStep = index;
      });
      return;
    }

    // 다음 페이지로 넘어가려고 할 때 검증
    bool validationPassed = false;

    if (_currentStep == 0) {
      // GlobalKey 사용 제거 - 버튼으로만 이동하므로 불필요
      validationPassed = _canGoToNextStep(viewModel);
    } else if (_currentStep == 1) {
      validationPassed = _canGoToNextStep(viewModel);
    }

    if (!validationPassed) {
      // 검증 실패 시 즉시 이전 페이지로 돌아감
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageController.jumpToPage(_currentStep);
        }
      });
      return;
    }

    setState(() {
      _currentStep = index;
    });
  }

  void _handleNextButtonPress(ItemAddViewModel viewModel) {
    // 가격·경매 카드에서 다음 버튼을 눌렀을 때 검증
    if (_currentStep == 1) {
      // GlobalKey 사용 제거 - 버튼 클릭시에만 필요하므로 불필요
      if (!_canGoToNextStep(viewModel)) {
        return;
      }
    }

    if (_currentStep < 2) {
      // 다음 단계로 이동
      _goToStep(_currentStep + 1);
    } else {
      // 최종 등록
      _showSubmitDialog(viewModel);
    }
  }

  void _showSubmitDialog(ItemAddViewModel viewModel) {
    showDialog(
      context: context,
      builder: (_) => AskPopup(
        content: '저장하시겠습니까?',
        noText: '취소',
        yesLogic: () async {
          Navigator.of(context).pop();
          await viewModel.submit(context);
        },
      ),
    );
  }

  Widget _buildSingleButtonBar(ItemAddViewModel viewModel) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: viewModel.titleController,
      builder: (context, titleValue, _) {
        return PrimaryButton(
          text: _getNextButtonText(),
          onPressed: () => _goToStep(_currentStep + 1),
          isEnabled: _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildDualButtonBar(ItemAddViewModel viewModel) {
    if (_currentStep == 0) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: viewModel.titleController,
        builder: (context, titleValue, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SecondaryButton(
                  text: '이전',
                  onPressed: () => _goToStep(_currentStep - 1),
                  width: null,
                ),
              ),
              SizedBox(width: context.spacingSmall),
              Expanded(
                child: PrimaryButton(
                  text: _getNextButtonText(),
                  onPressed: () => _handleNextButtonPress(viewModel),
                  isEnabled: _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
                  width: null,
                ),
              ),
            ],
          );
        },
      );
    } else if (_currentStep == 1) {
      // Step 1: Price/Auction checks startPrice, duration, and category
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: viewModel.startPriceController,
        builder: (context, priceValue, _) {
          return Selector<ItemAddViewModel, ({String? duration, int? keywordId})>(
            selector: (_, vm) => (
              duration: vm.selectedDuration,
              keywordId: vm.selectedKeywordTypeId,
            ),
            builder: (context, data, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: '이전',
                      onPressed: () => _goToStep(_currentStep - 1),
                      width: null,
                    ),
                  ),
                  SizedBox(width: context.spacingSmall),
                  Expanded(
                    child: PrimaryButton(
                      text: _getNextButtonText(),
                      onPressed: () => _handleNextButtonPress(viewModel),
                      isEnabled: _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
                      width: null,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } else if (_currentStep == 2) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: viewModel.descriptionController,
        builder: (context, descValue, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SecondaryButton(
                  text: '이전',
                  onPressed: () => _goToStep(_currentStep - 1),
                  width: null,
                ),
              ),
              SizedBox(width: context.spacingSmall),
              Expanded(
                child: PrimaryButton(
                  text: _getNextButtonText(),
                  onPressed: () => _handleNextButtonPress(viewModel),
                  isEnabled: _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
                  width: null,
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Others
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SecondaryButton(
              text: '이전',
              onPressed: () => _goToStep(_currentStep - 1),
              width: null,
            ),
          ),
          SizedBox(width: context.spacingSmall),
          Expanded(
            child: PrimaryButton(
              text: _getNextButtonText(),
              onPressed: () => _handleNextButtonPress(viewModel),
              isEnabled: _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
              width: null,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBottomNavigationBar(ItemAddViewModel viewModel) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: EdgeInsets.symmetric(
          horizontal: context.hPadding,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: chatItemCardBackground,
          boxShadow: [
            BoxShadow(
              color: shadowLow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _currentStep == 0
            ? _buildSingleButtonBar(viewModel)
            : _buildDualButtonBar(viewModel),
      ),
    );
  }

  late final ItemAddViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ItemAddViewModel>();
    _decorationCache = {};
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이미지 개수, 제출 상태를 감지하여 버튼 활성화 상태 업데이트
    // 제목은 별도로 감지하여 불필요한 재빌드 방지
    return Selector<
      ItemAddViewModel,
      ({int imageCount, bool isSubmitting})
    >(
      selector: (_, vm) => (
        imageCount: vm.selectedImages.length,
        isSubmitting: vm.isSubmitting,
      ),
      builder: (context, data, _) {
        final viewModel = _viewModel;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              context.go('/home');
            }
          },
          child: Scaffold(
            backgroundColor: BackgroundColor,
            appBar: AppBar(
              title: const Text('매물 작성'),
              centerTitle: true,
              backgroundColor: chatItemCardBackground,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // 스텝 인디케이터
                  StepIndicator(
                    currentStep: _currentStep,
                    totalSteps: 3,
                    stepLabels: _stepLabels,
                  ),
                  // 카드 영역
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) =>
                          _handlePageChange(index, viewModel),
                      children: [
                        // 카드 1: 상품 정보
                        ProductInfoCard(
                          viewModel: viewModel,
                          onImageSourceTap: () =>
                              _showImageSourceSheet(context, viewModel),
                          inputDecoration: (hint) => _inputDecoration(hint),
                        ),
                        // 카드 2: 가격·경매
                        PriceAuctionCard(
                          viewModel: viewModel,
                          inputDecoration: (hint) => _inputDecoration(hint),
                        ),
                        // 카드 3: 상세·확인
                        DetailConfirmCard(viewModel: viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(viewModel),
          ),
        );
      },
    );
  }
}
