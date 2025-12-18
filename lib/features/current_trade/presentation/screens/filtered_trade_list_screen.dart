import 'package:bidbird/core/utils/payment/payment_helper.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/visible_item_calculator.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item_trade/shipping/presentation/widgets/shipping_info_input_popup.dart';
import 'package:bidbird/features/item_trade/shipping/presentation/widgets/shipping_info_view_popup.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/trade_history_card.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/item_trade/shipping/data/repositories/shipping_info_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/current_trade/data/repositories/current_trade_repository.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/usecases/fetch_my_bid_history_usecase.dart';
import 'package:bidbird/features/current_trade/domain/usecases/fetch_my_sale_history_usecase.dart';
import 'package:bidbird/features/current_trade/presentation/utils/trade_item_filter.dart';
import 'package:bidbird/features/current_trade/presentation/viewmodels/current_trade_viewmodel.dart';

class FilteredTradeListScreen extends StatefulWidget {
  const FilteredTradeListScreen({
    super.key,
    required this.actionType,
    this.isSeller,
    this.actionTypes, // 여러 액션 타입을 받을 수 있도록 추가
  });

  final TradeActionType actionType;
  final bool? isSeller;
  final List<TradeActionType>? actionTypes; // 여러 액션 타입 지원

  @override
  State<FilteredTradeListScreen> createState() => _FilteredTradeListScreenState();
}

class _FilteredTradeListScreenState extends State<FilteredTradeListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _displayedItemCount = 0;
  bool _isLoadingMore = false;
  VoidCallback? _scrollListener;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 기존 ViewModel이 있으면 재사용, 없으면 새로 생성
    return _buildWithViewModel(context);
  }

  Widget _buildWithViewModel(BuildContext context) {
    // 기존 Provider에서 ViewModel 찾기
    CurrentTradeViewModel? existingViewModel;
    try {
      existingViewModel = Provider.of<CurrentTradeViewModel>(context, listen: false);
    } catch (e) {
      // Provider가 없으면 null
    }

    // 기존 ViewModel이 있으면 재사용
    if (existingViewModel != null) {
      // 데이터가 없고 로딩 중이 아니면 데이터 로드
      if (!existingViewModel.isLoading && 
          existingViewModel.bidHistory.isEmpty && 
          existingViewModel.saleHistory.isEmpty) {
        existingViewModel.loadData();
      }
      
      return Consumer<CurrentTradeViewModel>(
        builder: (context, viewModel, _) {
          return _buildContent(context, viewModel);
        },
      );
    }

    // 새 ViewModel 생성 (기존 Provider가 없는 경우)
    return ChangeNotifierProvider<CurrentTradeViewModel>(
      create: (_) => CurrentTradeViewModel(
        fetchMyBidHistoryUseCase: FetchMyBidHistoryUseCase(CurrentTradeRepositoryImpl()),
        fetchMySaleHistoryUseCase: FetchMySaleHistoryUseCase(CurrentTradeRepositoryImpl()),
      )..loadData(),
      child: Consumer<CurrentTradeViewModel>(
        builder: (context, viewModel, _) {
          return _buildContent(context, viewModel);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CurrentTradeViewModel viewModel) {
    // 여러 액션 타입이 제공되면 그것을 사용, 아니면 단일 actionType 사용
    final targetActionTypes = widget.actionTypes ?? [widget.actionType];
    
    // 판매 아이템 필터링
    final saleItems = widget.isSeller == null || widget.isSeller == true
        ? viewModel.saleHistory
            .where((item) => TradeItemFilter.shouldIncludeSaleItem(item, targetActionTypes))
            .toList()
        : <SaleHistoryItem>[];
    
    // 입찰 아이템 필터링
    final bidItems = widget.isSeller == null || widget.isSeller == false
        ? viewModel.bidHistory
            .where((item) => TradeItemFilter.shouldIncludeBidItem(item, targetActionTypes))
            .toList()
        : <BidHistoryItem>[];
    
    // 액션 타입별로 아이템 그룹화
    final itemsByActionType = TradeItemFilter.groupItemsByActionType(
      saleItems: saleItems,
      bidItems: bidItems,
      targetActionTypes: targetActionTypes,
    );

    final title = '처리 목록';

    // 전체 아이템 개수 확인
    final totalItems = itemsByActionType.values.fold<int>(0, (sum, items) => sum + items.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.error != null
                ? TransparentRefreshIndicator(
                    onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('오류가 발생했습니다: ${viewModel.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<CurrentTradeViewModel>().refresh(),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  )
                : totalItems == 0
                    ? TransparentRefreshIndicator(
                        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                        child: const Center(child: Text('해당 내역이 없습니다.')),
                  )
                : TransparentRefreshIndicator(
                    onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                    child: Builder(
                      builder: (context) {
                        final horizontalPadding = context.hPadding;
                        final verticalPadding = context.vPadding;
                        
                        // 모든 아이템을 하나의 리스트로 합치기 (섹션 헤더 포함)
                        final allSections = <Widget>[];
                        
                        // 액션 타입별로 섹션 생성
                        for (final actionType in targetActionTypes) {
                          final items = itemsByActionType[actionType];
                          if (items == null || items.isEmpty) continue;
                          
                          final sectionLabel = _getSectionLabel(actionType);
                          
                          // 섹션 내 아이템들의 역할 확인 (판매/구매)
                          final saleCount = items.whereType<SaleHistoryItem>().length;
                          final bidCount = items.whereType<BidHistoryItem>().length;
                          
                          // 섹션 색상 결정: 모두 판매면 초록색, 모두 구매면 파란색, 혼합이면 기본 파란색
                          final Color sectionColor;
                          if (saleCount > 0 && bidCount == 0) {
                            // 모두 판매
                            sectionColor = roleSalePrimary;
                          } else if (bidCount > 0 && saleCount == 0) {
                            // 모두 구매
                            sectionColor = rolePurchasePrimary;
                          } else {
                            // 혼합 또는 기본
                            sectionColor = blueColor;
                          }
                          
                          // 섹션 헤더
                          final spacing = ResponsiveConstants.spacingSmall(context);
                          final fontSize = ResponsiveConstants.fontSizeLarge(context);
                          allSections.add(
                            Padding(
                              padding: EdgeInsets.only(bottom: spacing, top: spacing),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: sectionColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  Text(
                                    sectionLabel,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          
                          // 섹션 아이템들
                          for (final item in items) {
                            final itemIsSeller = item is SaleHistoryItem;
                            final saleItem = itemIsSeller ? item : null;
                            final bidItem = itemIsSeller ? null : item as BidHistoryItem;
                            final itemActionType = saleItem?.actionType ?? bidItem?.actionType ?? TradeActionType.none;
                            
                            allSections.add(
                              Padding(
                                padding: EdgeInsets.only(bottom: spacing * 1.5),
                                child: TradeHistoryCard(
                                  title: saleItem?.title ?? bidItem?.title ?? '',
                                  thumbnailUrl: saleItem?.thumbnailUrl ?? bidItem?.thumbnailUrl,
                                  status: saleItem?.status ?? bidItem?.status ?? '',
                                  price: saleItem?.price ?? bidItem?.price ?? 0,
                                  itemId: saleItem?.itemId ?? bidItem?.itemId ?? '',
                                  isSeller: itemIsSeller,
                                  actionType: itemActionType,
                                  useResponsive: true,
                                  onActionButtonPressed: () => _buildActionButton(
                                    context,
                                    item,
                                    itemActionType,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                        
                        // 화면에 보이는 개수만큼만 표시 (코어 유틸리티 사용)
                        final initialVisibleCount = VisibleItemCalculator.calculateTradeHistoryVisibleCount(context);
                        
                        // 초기 로드 시 또는 아이템이 변경되었을 때 displayedItemCount 초기화
                        if (_displayedItemCount == 0 || _displayedItemCount > allSections.length) {
                          _displayedItemCount = initialVisibleCount.clamp(0, allSections.length);
                        }
                        
                        // displayedItemCount가 allSections.length를 초과하지 않도록 제한
                        _displayedItemCount = _displayedItemCount.clamp(0, allSections.length);
                        
                        // 스크롤 감지: 끝에서 200px 전에 도달하면 더 많은 아이템 표시
                        if (_scrollListener != null) {
                          _scrollController.removeListener(_scrollListener!);
                        }
                        _scrollListener = () {
                          if (_scrollController.position.pixels >=
                              _scrollController.position.maxScrollExtent - 200) {
                            if (!_isLoadingMore && _displayedItemCount < allSections.length && mounted) {
                              setState(() {
                                _isLoadingMore = true;
                                _displayedItemCount = (_displayedItemCount + initialVisibleCount).clamp(0, allSections.length);
                                _isLoadingMore = false;
                              });
                            }
                          }
                        };
                        _scrollController.addListener(_scrollListener!);
                        
                        final displaySections = allSections.take(_displayedItemCount).toList();
                        final hasMore = allSections.length > _displayedItemCount;
                        
                        return ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          children: [
                            ...displaySections,
                            // 더 보기 로딩 인디케이터 (화면에 보이는 개수보다 많을 때)
                            if (hasMore)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  String _getSectionLabel(TradeActionType actionType) {
    if (actionType == TradeActionType.none) {
      return '';
    }
    return ActionHubItem(actionType: actionType, count: 0).label;
  }


  Widget _buildActionButton(BuildContext context, dynamic item, TradeActionType actionType) {
    final isSeller = item is SaleHistoryItem;
    final saleItem = isSeller ? item : null;
    final bidItem = isSeller ? null : item as BidHistoryItem;
    final itemId = saleItem?.itemId ?? bidItem?.itemId ?? '';
    final title = saleItem?.title ?? bidItem?.title ?? '';
    final price = saleItem?.price ?? bidItem?.price ?? 0;

    switch (actionType) {
      case TradeActionType.paymentRequired:
        // 구매자: 결제하러 가기 버튼 표시
        return _buildActionButtonWidget(
          context: context,
          text: '결제하러 가기',
          onPressed: () async {
            await handlePayment(
              context: context,
              itemId: itemId,
              itemTitle: title,
              amount: price,
            );
          },
        );

      case TradeActionType.paymentWaiting:
        // 판매자: 결제 대기 상태 (버튼 없음)
        return const SizedBox.shrink();

      case TradeActionType.shippingInfoRequired:
        return _buildActionButtonWidget(
          context: context,
          text: '배송 정보 입력하기',
          onPressed: () => _handleShippingInfo(context, itemId),
        );

      case TradeActionType.purchaseConfirmRequired:
        return _buildActionButtonWidget(
          context: context,
          text: '구매 확정하기',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('구매 확정 기능은 준비 중입니다.')),
            );
          },
        );

      case TradeActionType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtonWidget({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Builder(
      builder: (context) {
        final buttonPadding = ResponsiveConstants.screenPadding(context);
        final buttonHeight = ResponsiveConstants.buttonHeight(context) * 2 / 3;
        final buttonFontSize = ResponsiveConstants.buttonFontSize(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(buttonPadding, 0, buttonPadding, buttonPadding),
          child: SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.7),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleShippingInfo(BuildContext context, String itemId) async {
    final shippingInfoRepository = ShippingInfoRepositoryImpl();
    try {
      final shippingInfo = await shippingInfoRepository.getShippingInfo(itemId);
      if (!context.mounted) return;
      
      final trackingNumber = shippingInfo?['tracking_number'];
      final hasShippingInfo = shippingInfo != null && 
          trackingNumber != null &&
          (trackingNumber is String && trackingNumber.isNotEmpty);
      
      if (hasShippingInfo) {
        showDialog(
          context: context,
          builder: (dialogContext) => ShippingInfoViewPopup(
            createdAt: shippingInfo['created_at'] is String ? shippingInfo['created_at'] as String : null,
            carrier: shippingInfo['carrier'] is String ? shippingInfo['carrier'] as String : null,
            trackingNumber: trackingNumber,
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            return ShippingInfoInputPopup(
              initialCarrier: shippingInfo != null && shippingInfo['carrier'] is String ? shippingInfo['carrier'] as String : null,
              initialTrackingNumber: trackingNumber is String ? trackingNumber : null,
              onConfirm: (carrier, trackingNumber) async {
                try {
                  if (shippingInfo != null) {
                    final existingTrackingNumber = shippingInfo['tracking_number'] as String?;
                    await shippingInfoRepository.updateShippingInfo(
                      itemId: itemId,
                      carrier: carrier,
                      trackingNumber: existingTrackingNumber ?? trackingNumber,
                    );
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('택배사 정보가 수정되었습니다')),
                      );
                    }
                  } else {
                    await shippingInfoRepository.saveShippingInfo(
                      itemId: itemId,
                      carrier: carrier,
                      trackingNumber: trackingNumber,
                    );
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('송장 정보가 입력되었습니다')),
                      );
                    }
                  }
                  // 팝업은 ShippingInfoInputPopup 내부에서 닫음
                  // 여기서는 refresh만 수행 (다음 프레임에서 실행하여 dispose 문제 방지)
                  if (context.mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        try {
                          context.read<CurrentTradeViewModel>().refresh();
                        } catch (e) {
                          // ViewModel이 dispose된 경우 무시
                        }
                      }
                    });
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('송장 정보 저장 실패: ${e.toString()}')),
                    );
                  }
                }
              },
            );
          },
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AskPopup(
          content: '배송 정보를 불러올 수 없습니다.',
          yesText: '확인',
          yesLogic: () async {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }
  }
}

