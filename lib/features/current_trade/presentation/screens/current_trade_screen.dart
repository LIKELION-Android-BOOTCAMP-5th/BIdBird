import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/visible_item_calculator.dart';
import 'package:bidbird/core/widgets/components/loading_indicator.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/trade_history_card.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/action_hub.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/presentation/viewmodels/current_trade_viewmodel.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _displayedItemCount = 0;
  bool _isLoadingMore = false;
  int _totalItemsCount = 0;
  int _initialVisibleCount = 0;
  bool _isScrollListenerAttached = false;

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
    
    // 스크롤 리스너를 한 번만 등록
    _scrollController.addListener(_handleScroll);
    _isScrollListenerAttached = true;
  }

  @override
  void dispose() {
    if (_isScrollListenerAttached) {
      _scrollController.removeListener(_handleScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _displayedItemCount < _totalItemsCount) {
        setState(() {
          _isLoadingMore = true;
          _displayedItemCount = (_displayedItemCount + _initialVisibleCount)
              .clamp(0, _totalItemsCount);
          _isLoadingMore = false;
        });
      }
    }
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
    // ViewModel의 캐싱된 필터링된 리스트를 직접 사용하도록 Selector 구성
    return Selector<CurrentTradeViewModel, ({
      List<SaleHistoryItem> filteredSaleItems,
      List<BidHistoryItem> filteredBidItems,
    })>(
      selector: (_, vm) => (
        filteredSaleItems: vm.filteredSaleItems,
        filteredBidItems: vm.filteredBidItems,
      ),
      builder: (context, data, _) {
        final filteredSaleItems = data.filteredSaleItems;
        final filteredBidItems = data.filteredBidItems;

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
              
              // 화면에 보이는 개수만큼만 표시 (코어 유틸리티 사용)
              _initialVisibleCount = VisibleItemCalculator.calculateTradeHistoryVisibleCount(context);
              _totalItemsCount = allItems.length;
              
              // 초기 로드 시 또는 아이템이 변경되었을 때 displayedItemCount 초기화
              if (_displayedItemCount == 0 || _displayedItemCount > allItems.length) {
                _displayedItemCount = _initialVisibleCount.clamp(0, allItems.length);
              }
              
              // displayedItemCount가 allItems.length를 초과하지 않도록 제한
              _displayedItemCount = _displayedItemCount.clamp(0, allItems.length);
              
              final displayItems = allItems.take(_displayedItemCount).toList();
              final hasMore = allItems.length > _displayedItemCount;
              
              return ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                itemCount: displayItems.length + (hasMore ? 1 : 0) + 1, // +1 for "전체 보기" 링크
                separatorBuilder: (_, __) => SizedBox(height: spacing),
                itemBuilder: (context, index) {
                  // "전체 보기" 링크는 항상 마지막에 표시
                  if (index == displayItems.length + (hasMore ? 1 : 0)) {
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
                  
                  // 더 보기 로딩 인디케이터 (화면에 보이는 개수보다 많을 때)
                  if (hasMore && index == displayItems.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : const SizedBox.shrink(),
                      ),
                    );
                  }

                  final itemData = displayItems[index];
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

