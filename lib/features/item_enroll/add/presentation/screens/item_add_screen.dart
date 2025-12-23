import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart' show parseFormattedPrice;
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/components/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey<PriceAuctionCardState> _priceAuctionCardKey = GlobalKey<PriceAuctionCardState>();
  final GlobalKey<ProductInfoCardState> _productInfoCardKey = GlobalKey<ProductInfoCardState>();
  int _currentStep = 0;

  static const List<String> _stepLabels = [
    '상품 정보',
    '가격·경매',
    '상세·확인',
  ];

  InputDecoration _inputDecoration(String hint) {
    return createStandardInputDecoration(
      context,
      hint: hint,
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
        final startPrice = parseFormattedPrice(viewModel.startPriceController.text);
        final hasValidStartPrice = startPrice > 0 && startPrice >= ItemPriceLimits.minPrice;
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
        
        return hasValidStartPrice && hasDuration && hasCategory && hasValidInstantPrice;
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
      _productInfoCardKey.currentState?.validateFields();
      validationPassed = _canGoToNextStep(viewModel);
    } else if (_currentStep == 1) {
      _priceAuctionCardKey.currentState?.validatePrices();
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
      _priceAuctionCardKey.currentState?.validatePrices();
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
    return PrimaryButton(
      text: _getNextButtonText(),
      onPressed: () => _goToStep(_currentStep + 1),
      isEnabled: _canGoToNextStep(viewModel) && !viewModel.isSubmitting,
      width: double.infinity,
    );
  }

  Widget _buildDualButtonBar(ItemAddViewModel viewModel) {
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
            isEnabled: !viewModel.isSubmitting,
            width: null,
          ),
        ),
      ],
    );
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
          color: Colors.white,
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
  late final ValueNotifier<int> _titleLengthNotifier;
  late final ValueNotifier<int> _startPriceLengthNotifier;
  late final ValueNotifier<int> _instantPriceLengthNotifier;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ItemAddViewModel>();
    _titleLengthNotifier = ValueNotifier<int>(_viewModel.titleController.text.length);
    _startPriceLengthNotifier =
        ValueNotifier<int>(_viewModel.startPriceController.text.length);
    _instantPriceLengthNotifier =
        ValueNotifier<int>(_viewModel.instantPriceController.text.length);

    _viewModel.titleController.addListener(_onTitleChanged);
    _viewModel.startPriceController.addListener(_onStartPriceChanged);
    _viewModel.instantPriceController.addListener(_onInstantPriceChanged);
  }

  void _onTitleChanged() {
    _titleLengthNotifier.value = _viewModel.titleController.text.length;
  }

  void _onStartPriceChanged() {
    _startPriceLengthNotifier.value = _viewModel.startPriceController.text.length;
  }

  void _onInstantPriceChanged() {
    _instantPriceLengthNotifier.value = _viewModel.instantPriceController.text.length;
  }

  @override
  void dispose() {
    _viewModel.titleController.removeListener(_onTitleChanged);
    _viewModel.startPriceController.removeListener(_onStartPriceChanged);
    _viewModel.instantPriceController.removeListener(_onInstantPriceChanged);
    _titleLengthNotifier.dispose();
    _startPriceLengthNotifier.dispose();
    _instantPriceLengthNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 필요한 속성만 watch하여 불필요한 리빌드 방지
    return Selector<ItemAddViewModel, ({
      int selectedImagesLength,
      String? selectedDuration,
      int? selectedKeywordTypeId,
      bool useInstantPrice,
      bool isSubmitting,
    })>(
      selector: (_, vm) => (
        selectedImagesLength: vm.selectedImages.length,
        selectedDuration: vm.selectedDuration,
        selectedKeywordTypeId: vm.selectedKeywordTypeId,
        useInstantPrice: vm.useInstantPrice,
        isSubmitting: vm.isSubmitting,
      ),
      builder: (context, data, _) {
        final viewModel = _viewModel;
        
        // 키보드 감지 - MediaQuery를 직접 사용하여 setState 없이 처리
        final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
              backgroundColor: Colors.white,
            ),
            body: Column(
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
                    physics: isKeyboardVisible || !_canGoToNextStep(viewModel)
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    onPageChanged: (index) => _handlePageChange(index, viewModel),
                    children: [
                      // 카드 1: 상품 정보
                      ProductInfoCard(
                        key: _productInfoCardKey,
                        viewModel: viewModel,
                        onImageSourceTap: () =>
                            _showImageSourceSheet(context, viewModel),
                        inputDecoration: (hint) => _inputDecoration(hint),
                      ),
                      // 카드 2: 가격·경매
                      PriceAuctionCard(
                        key: _priceAuctionCardKey,
                        viewModel: viewModel,
                        inputDecoration: (hint) => _inputDecoration(hint),
                      ),
                      // 카드 3: 상세·확인
                      DetailConfirmCard(
                        viewModel: viewModel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(viewModel),
          ),
        );
      },
    );
  }
}
