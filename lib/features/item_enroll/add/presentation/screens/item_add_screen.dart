import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/item/components/buttons/bottom_submit_button.dart';
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
  bool _isKeyboardVisible = false;

  static const List<String> _stepLabels = [
    '상품 정보',
    '가격·경매',
    '상세·확인',
  ];

  InputDecoration _inputDecoration(String hint, BuildContext? context) {
    if (context == null) {
      // Fallback for null context
      return createStandardInputDecoration(
        this.context,
        hint: hint,
      );
    }
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
        // 카드 2: 항상 활성화 (버튼 클릭 시 검증)
        return true;
      case 2:
        // 카드 3: 모든 검증 통과
        return viewModel.validate() == null;
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
        return '다음';
      case 2:
        return '등록하기';
      default:
        return '다음';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemAddViewModel viewModel = context.watch<ItemAddViewModel>();
    final horizontalPadding = context.hPadding;
    final bottomPadding = context.bottomPadding;
    
    // 키보드 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    // 키보드 상태가 변경되면 업데이트
    if (_isKeyboardVisible != isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKeyboardVisible = isKeyboardVisible;
          });
        }
      });
    }

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
          title: const Text('매물 등록'),
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
                physics: _isKeyboardVisible || !_canGoToNextStep(viewModel)
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (index) {
                  // 스와이프로 다음 페이지로 넘어가려고 할 때 검증
                  if (index > _currentStep) {
                    // 첫 번째 카드에서 두 번째 카드로 넘어가려고 할 때
                    if (_currentStep == 0) {
                      _productInfoCardKey.currentState?.validateFields();
                      if (!_canGoToNextStep(viewModel)) {
                        // 검증 실패 시 즉시 이전 페이지로 돌아감
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _pageController.jumpToPage(_currentStep);
                          }
                        });
                        return;
                      }
                    }
                    // 두 번째 카드에서 세 번째 카드로 넘어가려고 할 때
                    else if (_currentStep == 1) {
                      _priceAuctionCardKey.currentState?.validatePrices();
                      if (!_canGoToNextStep(viewModel)) {
                        // 검증 실패 시 즉시 이전 페이지로 돌아감
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _pageController.jumpToPage(_currentStep);
                          }
                        });
                        return;
                      }
                    }
                  }
                  
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // 카드 1: 상품 정보
                  ProductInfoCard(
                    key: _productInfoCardKey,
                    viewModel: viewModel,
                    onImageSourceTap: () =>
                        _showImageSourceSheet(context, viewModel),
                    inputDecoration: (hint) => _inputDecoration(hint, context),
                  ),
                  // 카드 2: 가격·경매
                  PriceAuctionCard(
                    key: _priceAuctionCardKey,
                    viewModel: viewModel,
                    inputDecoration: (hint) => _inputDecoration(hint, context),
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 72,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
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
                ? SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_canGoToNextStep(viewModel) &&
                              !viewModel.isSubmitting)
                          ? () {
                              if (_currentStep < 2) {
                                // 다음 단계로 이동
                                _goToStep(_currentStep + 1);
                              } else {
                                // 최종 등록
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
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: (_canGoToNextStep(viewModel) &&
                                !viewModel.isSubmitting)
                            ? blueColor
                            : BorderColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: BorderColor,
                        disabledForegroundColor: iconColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(defaultRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getNextButtonText(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이전 버튼
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _goToStep(_currentStep - 1),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: blueColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(defaultRadius),
                              ),
                            ),
                            child: Text(
                              '이전',
                              style: TextStyle(
                                color: blueColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacingSmall),
                      // 다음/등록 버튼
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: !viewModel.isSubmitting
                                ? () {
                                    // 가격·경매 카드에서 다음 버튼을 눌렀을 때 검증
                                    if (_currentStep == 1) {
                                      _priceAuctionCardKey.currentState?.validatePrices();
                                      // 검증 후 다시 확인
                                      if (!_canGoToNextStep(viewModel)) {
                                        return;
                                      }
                                    }
                                    
                                    if (_currentStep < 2) {
                                      // 다음 단계로 이동
                                      _goToStep(_currentStep + 1);
                                    } else {
                                      // 최종 등록
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
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: !viewModel.isSubmitting
                                  ? blueColor
                                  : BorderColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: BorderColor,
                              disabledForegroundColor: iconColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(defaultRadius),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _getNextButtonText(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
