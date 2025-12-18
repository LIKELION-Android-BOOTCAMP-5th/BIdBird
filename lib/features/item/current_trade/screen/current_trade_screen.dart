import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/loading_indicator.dart';
import 'package:bidbird/core/widgets/item/components/cards/trade_history_card.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bidbird/core/widgets/item/components/others/action_hub.dart';
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
            // Layer 2: 액션 허브 - 로딩/에러 상태만 Selector
            Selector<CurrentTradeViewModel, ({bool isLoading, String? error})>(
              selector: (_, vm) => (isLoading: vm.isLoading, error: vm.error),
              builder: (context, data, _) {
                if (!data.isLoading && data.error == null) {
                  return const _ActionHubSection();
                }
                return const SizedBox.shrink();
              },
            ),
            // Layer 3: 통합된 리스트
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 로딩 상태만 Selector
    return Selector<CurrentTradeViewModel, bool>(
      selector: (_, vm) => vm.isLoading,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const CenteredLoadingIndicator();
        }
        return _buildErrorOrContent();
      },
    );
  }

  Widget _buildErrorOrContent() {
    // 에러 상태만 Selector
    return Selector<CurrentTradeViewModel, String?>(
      selector: (_, vm) => vm.error,
      builder: (context, error, _) {
        if (error != null) {
          return TransparentRefreshIndicator(
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
                        error,
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
        
        return _buildUnifiedHistoryList();
      },
    );
  }

  Widget _buildUnifiedHistoryList() {
    // ViewModel의 캐싱된 getter를 사용하도록 Selector 구성
    return Selector<CurrentTradeViewModel, ({
      List<SaleHistoryItem> todoSaleItems,
      List<SaleHistoryItem> inProgressSaleItems,
      List<SaleHistoryItem> completedSaleItems,
      List<BidHistoryItem> todoBidItems,
      List<BidHistoryItem> inProgressBidItems,
      List<BidHistoryItem> completedBidItems,
    })>(
      selector: (_, vm) => (
        todoSaleItems: vm.todoSaleItems,
        inProgressSaleItems: vm.inProgressSaleItems,
        completedSaleItems: vm.completedSaleItems,
        todoBidItems: vm.todoBidItems,
        inProgressBidItems: vm.inProgressBidItems,
        completedBidItems: vm.completedBidItems,
      ),
      builder: (context, data, _) {
        // 판매와 입찰 내역을 필터링 (유찰 제외) - 지연 계산을 위해 getter로 처리
        final filteredSaleItems = [
          ...data.todoSaleItems,
          ...data.inProgressSaleItems,
          ...data.completedSaleItems,
        ].where((item) => !item.status.contains('유찰')).toList();
        
        final filteredBidItems = [
          ...data.todoBidItems,
          ...data.inProgressBidItems,
          ...data.completedBidItems,
        ].where((item) => !item.status.contains('유찰')).toList();

        final totalItemCount = filteredSaleItems.length + filteredBidItems.length;

        if (totalItemCount == 0) {
          return RefreshIndicator(
            onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
            child: const Center(child: Text('거래 내역이 없습니다.')),
          );
        }

        return TransparentRefreshIndicator(
          onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
          child: Builder(
            builder: (context) {
              final horizontalPadding = context.hPadding;
              final verticalPadding = context.vPadding;
              final spacing = context.spacingSmall;
              
              // 모든 아이템을 하나의 리스트로 합치기
              final allItems = <({bool isSeller, bool isHighlighted, dynamic item})>[];
              
              // 판매 아이템 추가
              for (var item in filteredSaleItems) {
                allItems.add((
                  isSeller: true,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                  item: item,
                ));
              }
              
              // 입찰 아이템 추가
              for (var item in filteredBidItems) {
                allItems.add((
                  isSeller: false,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                  item: item,
                ));
              }
              
              return ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                itemCount: allItems.length + 1, // +1 for "전체 보기" 링크
                separatorBuilder: (_, __) => SizedBox(height: spacing),
                itemBuilder: (context, index) {
                  // 마지막 아이템은 "전체 보기" 링크
                  if (index == allItems.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            context.push('/mypage/trade');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '전체 보기',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: textColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final itemData = allItems[index];
                  final item = itemData.item;
                  
                  if (itemData.isSeller) {
                    final saleItem = item as SaleHistoryItem;
                    return TradeHistoryCard(
                      title: saleItem.title,
                      thumbnailUrl: saleItem.thumbnailUrl,
                      status: saleItem.status,
                      price: saleItem.price,
                      itemId: saleItem.itemId,
                      isSeller: true,
                      isHighlighted: itemData.isHighlighted,
                    );
                  } else {
                    final bidItem = item as BidHistoryItem;
                    return TradeHistoryCard(
                      title: bidItem.title,
                      thumbnailUrl: bidItem.thumbnailUrl,
                      status: bidItem.status,
                      price: bidItem.price,
                      itemId: bidItem.itemId,
                      isSeller: false,
                      isHighlighted: itemData.isHighlighted,
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

// 액션 허브 섹션을 별도 위젯으로 분리
class _ActionHubSection extends StatelessWidget {
  const _ActionHubSection();

  @override
  Widget build(BuildContext context) {
    return Selector<CurrentTradeViewModel, ({
      List<ActionHubItem> saleActionHubItems,
      List<ActionHubItem> bidActionHubItems,
      List<SaleHistoryItem> todoSaleItems,
      List<BidHistoryItem> todoBidItems,
      List<SaleHistoryItem> saleHistory,
      List<BidHistoryItem> bidHistory,
    })>(
      selector: (_, vm) => (
        saleActionHubItems: vm.saleActionHubItems,
        bidActionHubItems: vm.bidActionHubItems,
        todoSaleItems: vm.todoSaleItems,
        todoBidItems: vm.todoBidItems,
        saleHistory: vm.saleHistory,
        bidHistory: vm.bidHistory,
      ),
      builder: (context, data, _) {
        return Column(
          children: [
            const SizedBox(height: 0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPadding),
              child: ActionHub(
                saleItems: data.saleActionHubItems,
                bidItems: data.bidActionHubItems,
                todoSaleItems: data.todoSaleItems,
                todoBidItems: data.todoBidItems,
                saleHistory: data.saleHistory,
                bidHistory: data.bidHistory,
              ),
            ),
            const SizedBox(height: 0),
          ],
        );
      },
    );
  }
}


