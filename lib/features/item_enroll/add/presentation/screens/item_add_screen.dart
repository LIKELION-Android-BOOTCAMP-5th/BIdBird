import 'package:bidbird/core/utils/item/item_price_utils.dart'
    show parseFormattedPrice;
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/widgets/components/pop_up/item_registration_terms_popup.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/components/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/item_add_viewmodel.dart';
import '../widgets/coach_mark/item-add_tutorial_controller.dart';
import '../widgets/step_indicator.dart';

import '../widgets/swipe_cards/item_detail_entry_card.dart';
import '../widgets/swipe_cards/price_auction_card.dart';
import '../widgets/swipe_cards/product_info_card.dart';

import 'package:bidbird/features/item_enroll/add/presentation/widgets/swipe_cards/preview_confirm_card.dart';

class ItemAddScreen extends StatefulWidget {
  const ItemAddScreen({super.key});

  @override
  State<ItemAddScreen> createState() => _ItemAddScreenState();
}

class _ItemAddScreenState extends State<ItemAddScreen> {
  late final ItemAddTutorialController _tutorialController;
  late final ItemAddViewModel _viewModel;
  late bool _canShowTutorial;

  //스탭 0
  final GlobalKey _cycleKey = GlobalKey();
  final GlobalKey _addPhotoKey = GlobalKey();
  final GlobalKey _addTitleKey = GlobalKey();
  //스탭 1
  final GlobalKey _startPriceKey = GlobalKey();
  final GlobalKey _bidScheduleKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  //스탭 2
  final GlobalKey _addContentKey = GlobalKey();
  final GlobalKey _addPDFKey = GlobalKey();

  final PageController _pageController = PageController();
  int _currentStep = 0;

  static const List<String> _stepLabels = ['상품 정보', '가격·경매', '상세 정보', '미리보기'];

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
    if (step >= 0 && step < 4) {
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

        return hasValidStartPrice &&
            hasDuration &&
            hasCategory &&
            hasValidInstantPrice;
      case 2:
        // 카드 3: 상세 정보 (검증 로직은 동일)
        return viewModel.validate() == null;
      case 3:
        // 카드 4: 미리보기 (등록 버튼은 Card 내부에 있음)
        return false;
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    return '다음';
  }

  void _handlePageChange(int index, ItemAddViewModel viewModel) {
    // UI 안정화 후 튜토리얼 표시
    setState(() => _currentStep = index);

    // 튜토리얼 차단
    if (!_canShowTutorial) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      _tutorialController.show(
        context: context,
        step: index,
        cycleKey: _cycleKey,
        addPhotoKey: _addPhotoKey,
        addTitleKey: _addTitleKey,
        startPriceKey: _startPriceKey,
        bidScheduleKey: _bidScheduleKey,
        categoryKey: _categoryKey,
        addContentKey: _addContentKey,
        addPDFKey: _addPDFKey,
        onSkipAll: _skipAllTutorial,
      );
    });
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
      validationPassed = _canGoToNextStep(viewModel);
    } else if (_currentStep == 1) {
      validationPassed = _canGoToNextStep(viewModel);
    } else if (_currentStep == 2) {
      validationPassed = _canGoToNextStep(viewModel);
    }

    if (!validationPassed) {
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
    if (_currentStep == 1) {
      if (!_canGoToNextStep(viewModel)) {
        // 가격/경매 단계에서 필수 입력값 누락 시 메시지 (보통 버튼이 비활성화되지만 만약을 위해)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 입력 항목을 확인해주세요.')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      final error = viewModel.validate();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      // 다음 단계로 이동
      _goToStep(_currentStep + 1);
    }
  }

  // coach mark 스킵 함수 -> 페이징 때문에 컨트롤러도 중단하는 로직 필요함
  void _skipAllTutorial() {
    // 로컬 저장
    _viewModel.markTutorialAsSeen();
    // 즉시 스텝 로직 중단
    _tutorialController.disable();
    // 화면 내에서도 차단
    _canShowTutorial = false;
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
                  isEnabled:
                      _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
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
          return Selector<
            ItemAddViewModel,
            ({String? duration, int? keywordId})
          >(
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
                      isEnabled:
                          _canGoToNextStep(viewModel) &&
                          !viewModel.isSubmitting,
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
                  text: '미리보기',
                  onPressed: () => _handleNextButtonPress(viewModel),
                  isEnabled: !viewModel.isSubmitting,
                  width: null,
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Others
      return const SizedBox.shrink(); 
    }
  }

  Widget _buildBottomNavigationBar(ItemAddViewModel viewModel) {
    // 미리보기에서도 바텀 네비게이션 바 사용 (위치 통일)
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
        child: _buildButtonBar(viewModel),
      ),
    );
  }

  Widget _buildButtonBar(ItemAddViewModel viewModel) {
    if (_currentStep == 0) {
      return _buildSingleButtonBar(viewModel);
    } else if (_currentStep == 1 || _currentStep == 2) {
      return _buildDualButtonBar(viewModel);
    } else if (_currentStep == 3) {
      // Step 3: Preview - Register Button
      return _buildRegisterButton(viewModel);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRegisterButton(ItemAddViewModel viewModel) {
    return PrimaryButton(
          text: '등록하기',
          onPressed: () {
            // 기존 약관 팝업 사용
            showDialog(
              context: context,
              builder: (dialogContext) => ItemRegistrationTermsPopup(
                title: ItemRegistrationTerms.popupTitle,
                sections: ItemRegistrationTerms.sections,
                checkLabel: ItemRegistrationTerms.checkLabel,
                onConfirm: (isChecked) {
                  if (isChecked) {
                    viewModel.submit(context);
                  }
                },
                onCancel: () {},
              ),
            );
          },
          isEnabled: !viewModel.isSubmitting,
          width: double.infinity,
        );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ItemAddViewModel>();
    _tutorialController = ItemAddTutorialController();
    _decorationCache = {};

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _canShowTutorial = await _viewModel.shouldShowTutorial();

      if (!_canShowTutorial) return;

      _tutorialController.show(
        context: context,
        step: 0,
        cycleKey: _cycleKey,
        addPhotoKey: _addPhotoKey,
        addTitleKey: _addTitleKey,
        startPriceKey: _startPriceKey,
        bidScheduleKey: _bidScheduleKey,
        categoryKey: _categoryKey,
        addContentKey: _addContentKey,
        addPDFKey: _addPDFKey,
        onSkipAll: _skipAllTutorial,
      );
    });
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
    return Selector<ItemAddViewModel, ({int imageCount, bool isSubmitting})>(
      selector: (_, vm) =>
          (imageCount: vm.selectedImages.length, isSubmitting: vm.isSubmitting),
      builder: (context, data, _) {
        final viewModel = _viewModel;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (_currentStep > 0) {
                 _goToStep(_currentStep - 1);
              } else {
                 context.go('/home');
              }
            }
          },
          child: Scaffold(
            backgroundColor: BackgroundColor,
            appBar: _currentStep == 3 
                ? null // 미리보기에서는 컴포넌트 내부 AppBar 사용 또는 숨김
                : AppBar(
                    title: const Text('매물 작성'),
                    centerTitle: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
            body: SafeArea(
              top: _currentStep != 3, // 미리보기 단계에서는 상태바 영역까지 확장
              bottom: false, // 미리보기에서 바텀 영역 침범 방지
              child: Column(
                children: [
                  // 스텝 인디케이터 (미리보기 제외)
                  if (_currentStep < 3) ...[
                    StepIndicator(
                      key: _cycleKey,
                      currentStep: _currentStep,
                      totalSteps: 4,
                      stepLabels: _stepLabels,
                    ),
                    const SizedBox(height: 20),
                  ],
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
                          addPhotoKey: _addPhotoKey,
                          addTitleKey: _addTitleKey,
                          viewModel: viewModel,
                          onImageSourceTap: () =>
                              _showImageSourceSheet(context, viewModel),
                          inputDecoration: (hint) => _inputDecoration(hint),
                        ),
                        // 카드 2: 가격·경매
                        PriceAuctionCard(
                          startPriceKey: _startPriceKey,
                          bidScheduleKey: _bidScheduleKey,
                          categoryKey: _categoryKey,
                          viewModel: viewModel,
                          inputDecoration: (hint) => _inputDecoration(hint),
                        ),
                        // 카드 3: 상세 정보
                        ItemDetailEntryCard(
                          addContentKey: _addContentKey,
                          addPDFKey: _addPDFKey,
                          viewModel: viewModel,
                          inputDecoration: (hint) => _inputDecoration(hint),
                        ),
                        // 카드 4: 미리보기
                        PreviewConfirmCard(
                          viewModel: viewModel,
                          onBack: () => _goToStep(_currentStep - 1),
                        ),
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
