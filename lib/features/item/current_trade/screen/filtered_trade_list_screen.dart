
import 'package:bidbird/core/utils/payment/payment_helper.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_input_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_view_popup.dart';
import 'package:bidbird/core/widgets/item/trade_history_card.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository/current_trade_repository.dart';
import '../model/current_trade_entity.dart';
import '../viewmodel/current_trade_viewmodel.dart';

class FilteredTradeListScreen extends StatelessWidget {
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
        repository: CurrentTradeRepositoryImpl(),
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
    final targetActionTypes = actionTypes ?? [actionType];
    
    // 액션 타입에 맞는 항목 필터링
    final List<dynamic> filteredItems;
    
    // 필터링 헬퍼 함수
    bool shouldIncludeSaleItem(SaleHistoryItem item) {
      // actionType이 none이 아니고 targetActionTypes에 포함되면 포함
      if (item.actionType != TradeActionType.none && 
          targetActionTypes.contains(item.actionType)) {
        return true;
      }
      // actionType이 none이면 tradeStatusCode로 직접 판단
      if (item.actionType == TradeActionType.none) {
        if (item.tradeStatusCode == 510 && 
            targetActionTypes.contains(TradeActionType.paymentRequired)) {
          return true;
        }
        if (item.tradeStatusCode == 520 && !item.hasShippingInfo &&
            targetActionTypes.contains(TradeActionType.shippingInfoRequired)) {
          return true;
        }
      }
      return false;
    }
    
    bool shouldIncludeBidItem(BidHistoryItem item) {
      // actionType이 none이 아니고 targetActionTypes에 포함되면 포함
      if (item.actionType != TradeActionType.none && 
          targetActionTypes.contains(item.actionType)) {
        return true;
      }
      // actionType이 none이면 tradeStatusCode로 직접 판단
      if (item.actionType == TradeActionType.none) {
        if (item.tradeStatusCode == 510 && 
            targetActionTypes.contains(TradeActionType.paymentRequired)) {
          return true;
        }
        if (item.tradeStatusCode == 520 && item.hasShippingInfo &&
            targetActionTypes.contains(TradeActionType.purchaseConfirmRequired)) {
          return true;
        }
      }
      // auction_status_code=321이고 tradeStatusCode가 없으면 결제 대기
      if ((item.tradeStatusCode == null || item.tradeStatusCode == 0) &&
          item.auctionStatusCode == 321 &&
          targetActionTypes.contains(TradeActionType.paymentRequired)) {
        return true;
      }
      return false;
    }
    
    // 액션 타입별로 아이템 그룹화
    final Map<TradeActionType, List<dynamic>> itemsByActionType = {};
    
    // 각 액션 타입별로 아이템 수집
    for (final actionType in targetActionTypes) {
      itemsByActionType[actionType] = [];
    }
    
    // 판매 아이템 분류
    final saleItems = isSeller == null || isSeller == true
        ? viewModel.saleHistory.where(shouldIncludeSaleItem).toList()
        : <SaleHistoryItem>[];
    
    for (final item in saleItems) {
      TradeActionType? itemActionType;
      if (item.actionType != TradeActionType.none) {
        itemActionType = item.actionType;
      } else {
        if (item.tradeStatusCode == 510) {
          itemActionType = TradeActionType.paymentRequired;
        } else if (item.tradeStatusCode == 520 && !item.hasShippingInfo) {
          itemActionType = TradeActionType.shippingInfoRequired;
        }
      }
      if (itemActionType != null && itemsByActionType.containsKey(itemActionType)) {
        itemsByActionType[itemActionType]!.add(item);
      }
    }
    
    // 입찰 아이템 분류
    final bidItems = isSeller == null || isSeller == false
        ? viewModel.bidHistory.where(shouldIncludeBidItem).toList()
        : <BidHistoryItem>[];
    
    for (final item in bidItems) {
      TradeActionType? itemActionType;
      if (item.actionType != TradeActionType.none) {
        itemActionType = item.actionType;
      } else {
        if (item.tradeStatusCode == 510) {
          itemActionType = TradeActionType.paymentRequired;
        } else if (item.tradeStatusCode == 520 && item.hasShippingInfo) {
          itemActionType = TradeActionType.purchaseConfirmRequired;
        } else if ((item.tradeStatusCode == null || item.tradeStatusCode == 0) &&
                   item.auctionStatusCode == 321) {
          itemActionType = TradeActionType.paymentRequired;
        }
      }
      if (itemActionType != null && itemsByActionType.containsKey(itemActionType)) {
        itemsByActionType[itemActionType]!.add(item);
      }
    }

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
                ? RefreshIndicator(
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
                    ? RefreshIndicator(
                        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                        child: const Center(child: Text('해당 내역이 없습니다.')),
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                    child: Builder(
                      builder: (context) {
                        final screenPadding = ResponsiveConstants.screenPadding(context);
                        return ListView(
                          padding: EdgeInsets.all(screenPadding),
                          children: [
                            // 액션 타입별로 섹션 생성
                            ...targetActionTypes.where((actionType) {
                              return itemsByActionType[actionType]?.isNotEmpty ?? false;
                            }).expand((actionType) {
                              final items = itemsByActionType[actionType]!;
                              final sectionLabel = _getSectionLabel(actionType);
                              
                              // 섹션 내 아이템들의 역할 확인 (판매/구매)
                              final saleCount = items.where((item) => item is SaleHistoryItem).length;
                              final bidCount = items.where((item) => item is BidHistoryItem).length;
                              
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
                              
                              return [
                                // 섹션 헤더
                                Builder(
                                  builder: (context) {
                                    final spacing = ResponsiveConstants.spacingSmall(context);
                                    final fontSize = ResponsiveConstants.fontSizeLarge(context);
                                    return Padding(
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
                                    );
                                  },
                                ),
                                // 섹션 아이템들
                                ...items.map((item) {
                                  final itemIsSeller = item is SaleHistoryItem;
                                  final itemActionType = itemIsSeller
                                      ? (item as SaleHistoryItem).actionType
                                      : (item as BidHistoryItem).actionType;
                                  return Builder(
                                    builder: (context) {
                                      final spacing = ResponsiveConstants.spacingSmall(context);
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: spacing * 1.5),
                                        child: TradeHistoryCard(
                                          title: itemIsSeller
                                              ? (item as SaleHistoryItem).title
                                              : (item as BidHistoryItem).title,
                                          thumbnailUrl: itemIsSeller
                                              ? (item as SaleHistoryItem).thumbnailUrl
                                              : (item as BidHistoryItem).thumbnailUrl,
                                          status: itemIsSeller
                                              ? (item as SaleHistoryItem).status
                                              : (item as BidHistoryItem).status,
                                          price: itemIsSeller
                                              ? (item as SaleHistoryItem).price
                                              : (item as BidHistoryItem).price,
                                          itemId: itemIsSeller
                                              ? (item as SaleHistoryItem).itemId
                                              : (item as BidHistoryItem).itemId,
                                          isSeller: itemIsSeller,
                                          actionType: itemActionType,
                                          useResponsive: true,
                                          onActionButtonPressed: () => _buildActionButton(
                                            context,
                                            item,
                                            itemActionType,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ];
                            }),
                          ],
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  String _getTitle(TradeActionType actionType) {
    switch (actionType) {
      case TradeActionType.paymentRequired:
        return '결제 대기';
      case TradeActionType.shippingInfoRequired:
        return '배송지 입력';
      case TradeActionType.purchaseConfirmRequired:
        return '구매 확정';
      case TradeActionType.none:
        return '현재 거래 내역';
    }
  }

  String _getSectionLabel(TradeActionType actionType) {
    switch (actionType) {
      case TradeActionType.paymentRequired:
        return '결제 대기';
      case TradeActionType.shippingInfoRequired:
        return '배송지 입력';
      case TradeActionType.purchaseConfirmRequired:
        return '구매 확정';
      case TradeActionType.none:
        return '';
    }
  }


  Widget _buildActionButton(BuildContext context, dynamic item, TradeActionType actionType) {
    final isSeller = item is SaleHistoryItem;
    final itemId = isSeller ? (item as SaleHistoryItem).itemId : (item as BidHistoryItem).itemId;
    final title = isSeller ? (item as SaleHistoryItem).title : (item as BidHistoryItem).title;
    final price = isSeller ? (item as SaleHistoryItem).price : (item as BidHistoryItem).price;

    switch (actionType) {
      case TradeActionType.paymentRequired:
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
                  onPressed: () async {
                    await handlePayment(
                      context: context,
                      itemId: itemId,
                      itemTitle: title,
                      amount: price,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: Text(
                    '결제하러 가기',
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

      case TradeActionType.shippingInfoRequired:
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
                  onPressed: () => _handleShippingInfo(context, itemId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: Text(
                    '배송 정보 입력하기',
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

      case TradeActionType.purchaseConfirmRequired:
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
                  onPressed: () {
                    // 구매 확정 기능 구현 필요
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매 확정 기능은 준비 중입니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: Text(
                    '구매 확정하기',
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

      case TradeActionType.none:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleShippingInfo(BuildContext context, String itemId) async {
    final shippingInfoRepository = ShippingInfoRepository();
    try {
      final shippingInfo = await shippingInfoRepository.getShippingInfo(itemId);
      if (!context.mounted) return;
      
      final hasShippingInfo = shippingInfo != null && 
          shippingInfo['tracking_number'] != null &&
          (shippingInfo['tracking_number'] as String?)?.isNotEmpty == true;
      
      if (hasShippingInfo) {
        showDialog(
          context: context,
          builder: (dialogContext) => ShippingInfoViewPopup(
            createdAt: shippingInfo?['created_at'] as String?,
            carrier: shippingInfo?['carrier'] as String?,
            trackingNumber: shippingInfo?['tracking_number'] as String?,
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            return ShippingInfoInputPopup(
              initialCarrier: shippingInfo?['carrier'] as String?,
              initialTrackingNumber: shippingInfo?['tracking_number'] as String?,
              onConfirm: (carrier, trackingNumber) async {
                try {
                  if (shippingInfo != null) {
                    final existingTrackingNumber = shippingInfo?['tracking_number'] as String?;
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

  String _formatMoney(int value) {
    final s = value.toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$formatted원';
  }
}
