import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/payment/payment_helper.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_input_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_view_popup.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                                        child: _buildHistoryCard(context, item, itemIsSeller, itemActionType),
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

  Widget _buildHistoryCard(BuildContext context, dynamic item, bool isSeller, TradeActionType actionType) {
    // 역할 색상 결정
    final roleColor = isSeller ? roleSalePrimary : rolePurchasePrimary;
    final roleSubColor = isSeller ? roleSaleSub : rolePurchaseSub;
    final roleTextColor = isSeller ? roleSaleText : rolePurchaseText;
    final roleLabel = isSeller ? '판매' : '구매';

    if (isSeller) {
      final saleItem = item as SaleHistoryItem;
      return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: defaultBorder,
            border: Border.all(
              color: BorderColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // 좌측 역할 인디케이터 스트립
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(defaultRadius),
                      bottomLeft: Radius.circular(defaultRadius),
                    ),
                  ),
                ),
                // 메인 컨텐츠
                Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (saleItem.itemId.isNotEmpty) {
                        context.push('/item/${saleItem.itemId}');
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final cardPadding = ResponsiveConstants.screenPadding(context);
                        return Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 썸네일
                                  Builder(
                                    builder: (context) {
                                      final thumbnailSize = context.widthRatio(0.16, min: 64.0, max: 80.0);
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: thumbnailSize,
                                          height: thumbnailSize,
                                          color: BackgroundColor,
                                          child: saleItem.thumbnailUrl != null &&
                                                  saleItem.thumbnailUrl!.isNotEmpty
                                            ? Builder(
                                                builder: (context) {
                                                  final bool isVideo = isVideoFile(saleItem.thumbnailUrl!);
                                                  final String displayUrl = isVideo
                                                      ? getVideoThumbnailUrl(saleItem.thumbnailUrl!)
                                                      : saleItem.thumbnailUrl!;
                                                  
                                                  return CachedNetworkImage(
                                                    imageUrl: displayUrl,
                                                    cacheManager: ItemImageCacheManager.instance,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Container(
                                                      color: BackgroundColor,
                                                      child: const Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      color: BackgroundColor,
                                                      child: const Icon(
                                                        Icons.image_outlined,
                                                        color: BorderColor,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : const Icon(Icons.image_outlined, color: BorderColor),
                                        ),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final spacing = ResponsiveConstants.spacingSmall(context);
                                      return SizedBox(width: spacing);
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 역할 태그와 제목
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 역할 태그
                                            Builder(
                                              builder: (context) {
                                                final tagPadding = ResponsiveConstants.spacingSmall(context) * 0.5;
                                                final tagFontSize = ResponsiveConstants.fontSizeSmall(context);
                                                final spacing = ResponsiveConstants.spacingSmall(context);
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: tagPadding,
                                                    vertical: tagPadding * 0.4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: roleSubColor,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    roleLabel,
                                                    style: TextStyle(
                                                      color: roleTextColor,
                                                      fontSize: tagFontSize,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final spacing = ResponsiveConstants.spacingSmall(context) * 0.5;
                                                return SizedBox(width: spacing);
                                              },
                                            ),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  final titleFontSize = ResponsiveConstants.fontSizeMedium(context);
                                                  return Text(
                                                    saleItem.title,
                                                    style: TextStyle(fontSize: titleFontSize),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final spacing = ResponsiveConstants.spacingSmall(context);
                                            return SizedBox(height: spacing);
                                          },
                                        ),
                                        // 상태 배지와 가격
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final badgePadding = ResponsiveConstants.spacingSmall(context) * 0.8;
                                                final badgeFontSize = ResponsiveConstants.fontSizeSmall(context);
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: badgePadding,
                                                    vertical: badgePadding * 0.4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: getTradeStatusColor(saleItem.status)
                                                        .withValues(alpha: 0.1),
                                                    borderRadius: defaultBorder,
                                                  ),
                                                  child: Text(
                                                    saleItem.status,
                                                    style: TextStyle(
                                                      color: getTradeStatusColor(saleItem.status),
                                                      fontSize: badgeFontSize,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final priceFontSize = ResponsiveConstants.fontSizeMedium(context);
                                                return Text(
                                                  _formatMoney(saleItem.price),
                                                  style: TextStyle(
                                                    fontSize: priceFontSize,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                    },
                  ),
                  ),
                  // 하단 액션 버튼
                  _buildActionButton(context, saleItem, actionType),
                ],
              ),
            ),
          ],
        ),
      ),
      );
    } else {
      final bidItem = item as BidHistoryItem;
      return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: defaultBorder,
            border: Border.all(
              color: BorderColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // 좌측 역할 인디케이터 스트립
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(defaultRadius),
                      bottomLeft: Radius.circular(defaultRadius),
                    ),
                  ),
                ),
                // 메인 컨텐츠
                Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (bidItem.itemId.isNotEmpty) {
                        context.push('/item/${bidItem.itemId}');
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final cardPadding = ResponsiveConstants.screenPadding(context);
                        return Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 썸네일
                                  Builder(
                                    builder: (context) {
                                      final thumbnailSize = context.widthRatio(0.16, min: 64.0, max: 80.0);
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: thumbnailSize,
                                          height: thumbnailSize,
                                          color: BackgroundColor,
                                          child: bidItem.thumbnailUrl != null &&
                                                  bidItem.thumbnailUrl!.isNotEmpty
                                            ? Builder(
                                                builder: (context) {
                                                  final bool isVideo = isVideoFile(bidItem.thumbnailUrl!);
                                                  final String displayUrl = isVideo
                                                      ? getVideoThumbnailUrl(bidItem.thumbnailUrl!)
                                                      : bidItem.thumbnailUrl!;
                                                  
                                                  return CachedNetworkImage(
                                                    imageUrl: displayUrl,
                                                    cacheManager: ItemImageCacheManager.instance,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Container(
                                                      color: BackgroundColor,
                                                      child: const Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      color: BackgroundColor,
                                                      child: const Icon(
                                                        Icons.image_outlined,
                                                        color: BorderColor,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : const Icon(Icons.image_outlined, color: BorderColor),
                                        ),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final spacing = ResponsiveConstants.spacingSmall(context);
                                      return SizedBox(width: spacing);
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 역할 태그와 제목
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 역할 태그
                                            Builder(
                                              builder: (context) {
                                                final tagPadding = ResponsiveConstants.spacingSmall(context) * 0.5;
                                                final tagFontSize = ResponsiveConstants.fontSizeSmall(context);
                                                final spacing = ResponsiveConstants.spacingSmall(context);
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: tagPadding,
                                                    vertical: tagPadding * 0.4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: roleSubColor,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    roleLabel,
                                                    style: TextStyle(
                                                      color: roleTextColor,
                                                      fontSize: tagFontSize,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final spacing = ResponsiveConstants.spacingSmall(context) * 0.5;
                                                return SizedBox(width: spacing);
                                              },
                                            ),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  final titleFontSize = ResponsiveConstants.fontSizeMedium(context);
                                                  return Text(
                                                    bidItem.title,
                                                    style: TextStyle(fontSize: titleFontSize),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final spacing = ResponsiveConstants.spacingSmall(context);
                                            return SizedBox(height: spacing);
                                          },
                                        ),
                                        // 상태 배지와 가격
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final badgePadding = ResponsiveConstants.spacingSmall(context) * 0.8;
                                                final badgeFontSize = ResponsiveConstants.fontSizeSmall(context);
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: badgePadding,
                                                    vertical: badgePadding * 0.4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: getTradeStatusColor(bidItem.status)
                                                        .withValues(alpha: 0.1),
                                                    borderRadius: defaultBorder,
                                                  ),
                                                  child: Text(
                                                    bidItem.status,
                                                    style: TextStyle(
                                                      color: getTradeStatusColor(bidItem.status),
                                                      fontSize: badgeFontSize,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final priceFontSize = ResponsiveConstants.fontSizeMedium(context);
                                                return Text(
                                                  _formatMoney(bidItem.price),
                                                  style: TextStyle(
                                                    fontSize: priceFontSize,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                    },
                  ),
                  ),
                  // 하단 액션 버튼
                  _buildActionButton(context, bidItem, actionType),
                ],
              ),
            ),
          ],
        ),
      ),
      );
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
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    context.read<CurrentTradeViewModel>().refresh();
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
