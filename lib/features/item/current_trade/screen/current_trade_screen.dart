import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui_set/border_radius_style.dart';
import '../model/current_trade_entity.dart';
import '../viewmodel/current_trade_viewmodel.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  @override
  void initState() {
    super.initState();
    // 데이터 로드가 안 되어 있으면 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<CurrentTradeViewModel>();
      if (viewModel.bidHistory.isEmpty && 
          viewModel.saleHistory.isEmpty && 
          !viewModel.isLoading) {
        viewModel.loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CurrentTradeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('현재 거래 내역'), NotificationButton()],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Layer 2: 액션 허브
            if (!viewModel.isLoading && viewModel.error == null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ActionHub(
                  saleItems: viewModel.saleActionHubItems,
                  bidItems: viewModel.bidActionHubItems,
                  todoSaleItems: viewModel.todoSaleItems,
                  todoBidItems: viewModel.todoBidItems,
                  saleHistory: viewModel.saleHistory,
                  bidHistory: viewModel.bidHistory,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox.shrink(),
            ],
            // Layer 3: 통합된 리스트
            Expanded(
              child: _buildContent(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CurrentTradeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewModel.error != null) {
      return RefreshIndicator(
        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.error ?? '오류가 발생했습니다.',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CurrentTradeViewModel>().refresh(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return _buildUnifiedHistoryList(viewModel);
  }

  Widget _buildUnifiedHistoryList(CurrentTradeViewModel viewModel) {
    // 판매와 입찰 내역을 모두 합치기
    final allSaleItems = [
      ...viewModel.todoSaleItems,
      ...viewModel.inProgressSaleItems,
      ...viewModel.completedSaleItems,
    ].where((item) => !item.status.contains('유찰')).toList();
    
    final allBidItems = [
      ...viewModel.todoBidItems,
      ...viewModel.inProgressBidItems,
      ...viewModel.completedBidItems,
    ].where((item) => !item.status.contains('유찰')).toList();

    if (allSaleItems.isEmpty && allBidItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
        child: const Center(child: Text('거래 내역이 없습니다.')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // 판매 내역
          ...allSaleItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryCard(
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl,
                  status: item.status,
                  price: item.price,
                  itemId: item.itemId,
                  actionType: item.actionType,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                  date: item.date,
                  isSeller: true,
                ),
              )),
          // 입찰 내역
          ...allBidItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryCard(
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl,
                  status: item.status,
                  price: item.price,
                  itemId: item.itemId,
                  actionType: item.actionType,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                  isSeller: false,
                ),
              )),
          // 전체 보기 링크
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  context.push('/mypage/trade');
                },
                child: Text(
                  '전체 보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    decoration: TextDecoration.underline,
                    decorationColor: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 액션 허브 위젯 (Layer 2)
class _ActionHub extends StatelessWidget {
  const _ActionHub({
    required this.saleItems,
    required this.bidItems,
    required this.todoSaleItems,
    required this.todoBidItems,
    required this.saleHistory,
    required this.bidHistory,
  });

  final List<ActionHubItem> saleItems;
  final List<ActionHubItem> bidItems;
  final List<dynamic> todoSaleItems;
  final List<dynamic> todoBidItems;
  final List<dynamic> saleHistory;
  final List<dynamic> bidHistory;

  @override
  Widget build(BuildContext context) {
    // 판매와 입찰 액션을 합치고 중복 제거
    final Map<TradeActionType, int> combinedCounts = {};
    
    // 판매 내역 확인
    for (final item in saleHistory) {
      TradeActionType? actionType;
      
      // tradeStatusCode를 직접 확인
      if (item.tradeStatusCode == 510) {
        actionType = TradeActionType.paymentRequired;
      } else if (item.tradeStatusCode == 520 && !item.hasShippingInfo) {
        actionType = TradeActionType.shippingInfoRequired;
      }
      
      if (actionType != null) {
        final beforeCount = combinedCounts[actionType] ?? 0;
        combinedCounts[actionType] = beforeCount + 1;
      }
    }
    
    // 입찰 내역 확인
    for (final item in bidHistory) {
      TradeActionType? actionType;
      
      // tradeStatusCode를 직접 확인
      if (item.tradeStatusCode == 510) {
        actionType = TradeActionType.paymentRequired;
      } else if (item.tradeStatusCode == 520) {
        // 입찰 내역: 520이면 구매 확정 가능 (배송 정보 있으면 확정, 없으면 대기)
        if (item.hasShippingInfo) {
          actionType = TradeActionType.purchaseConfirmRequired;
        }
      } else if ((item.tradeStatusCode == null || item.tradeStatusCode == 0) && 
                 item.auctionStatusCode == 321) {
        // 입찰 낙찰 상태이고 trade_status_code가 없으면 결제 대기로 간주
        actionType = TradeActionType.paymentRequired;
      }
      
      if (actionType != null) {
        final beforeCount = combinedCounts[actionType] ?? 0;
        combinedCounts[actionType] = beforeCount + 1;
      }
    }
    
    final combinedItems = combinedCounts.entries
        .where((e) => e.value > 0) // 0건인 항목은 제외
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();
    
    combinedItems.sort((a, b) => b.count.compareTo(a.count));
    
    // 전체 건수 계산 (0건이어도 표시)
    final totalCount = combinedItems.fold<int>(0, (sum, item) => sum + item.count);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 통합 액션 박스
        GestureDetector(
          onTap: () {
            // 모든 처리해야 할 거래를 보여주는 화면으로 이동
            if (combinedItems.isNotEmpty) {
              final actionTypes = combinedItems.map((item) => item.actionType).toList();
              context.push(
                '/bid/filtered',
                extra: {
                  'actionType': combinedItems.first.actionType, // 호환성을 위해 첫 번째 것도 전달
                  'actionTypes': actionTypes, // 모든 액션 타입 전달
                  'isSeller': null, // 판매와 입찰 모두 표시
                },
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: blueColor,
              borderRadius: defaultBorder,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지금 처리해야 할 거래 $totalCount건',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (combinedItems.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        // 액션 타입들을 한 줄로 표시
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: combinedItems.map((item) {
                            return Text(
                              '${item.label} ${item.count}건',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          '처리할 거래가 없습니다',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.thumbnailUrl,
    required this.status,
    required this.price,
    required this.itemId,
    required this.actionType,
    this.isHighlighted = false,
    this.date,
    this.isSeller = false, // 판매/입찰 구분용
  });

  final String title;
  final String? thumbnailUrl;
  final String status;
  final int price;
  final String itemId;
  final TradeActionType actionType;
  final bool isHighlighted;
  final String? date;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    // 역할 색상 결정
    final roleColor = isSeller ? roleSalePrimary : rolePurchasePrimary;
    final roleSubColor = isSeller ? roleSaleSub : rolePurchaseSub;
    final roleTextColor = isSeller ? roleSaleText : rolePurchaseText;
    final roleLabel = isSeller ? '판매' : '구매';

    return GestureDetector(
      onTap: () {
        if (itemId.isNotEmpty) {
          context.push('/item/$itemId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          border: Border.all(
            color: BorderColor.withValues(alpha: 0.25),
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: blueColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
                child: Padding(
                  padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 썸네일
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: BackgroundColor,
                            child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                                ? Builder(
                                    builder: (context) {
                                      final bool isVideo = isVideoFile(thumbnailUrl!);
                                      final String displayUrl = isVideo
                                          ? getVideoThumbnailUrl(thumbnailUrl!)
                                          : thumbnailUrl!;
                                      
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 역할 태그와 제목
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 역할 태그
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: roleSubColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: TextStyle(
                                        color: roleTextColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontSize: 15),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 상태 배지와 가격
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getTradeStatusColor(status).withValues(alpha: 0.1),
                                      borderRadius: defaultBorder,
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: getTradeStatusColor(status),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(price),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
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
              ),
            ),
          ],
          ),
        ),
      ),
    );
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
