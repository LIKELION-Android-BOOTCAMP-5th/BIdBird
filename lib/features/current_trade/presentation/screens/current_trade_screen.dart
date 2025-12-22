import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/visible_item_calculator.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/presentation/viewmodels/current_trade_viewmodel.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/action_hub.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/trade_history_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _PaginationController {
  _PaginationController({required this.onLoadMore});

  final VoidCallback onLoadMore;
  int _displayedCount = 0;
  int _totalCount = 0;
  int _initialVisibleCount = 0;
  bool isLoadingMore = false;

  int get displayedCount => _displayedCount;
  bool get hasMore => _displayedCount < _totalCount;

  void updateTotals({
    required int totalCount,
    required int initialVisibleCount,
  }) {
    final totalsChanged =
        _totalCount != totalCount || _initialVisibleCount != initialVisibleCount;
    _totalCount = totalCount;
    _initialVisibleCount = initialVisibleCount;

    if (_displayedCount == 0 || totalsChanged) {
      _displayedCount = _initialVisibleCount.clamp(0, _totalCount);
    } else {
      _displayedCount = _displayedCount.clamp(0, _totalCount);
    }
  }

  void handleScroll(ScrollPosition position) {
    if (!hasMore || isLoadingMore) return;
    final threshold = position.maxScrollExtent - 200;
    if (position.pixels >= threshold) {
      tryLoadMore();
    }
  }

  bool tryLoadMore() {
    if (!hasMore || isLoadingMore) return false;
    isLoadingMore = true;
    _displayedCount = (_displayedCount + _initialVisibleCount).clamp(
      0,
      _totalCount,
    );
    isLoadingMore = false;
    onLoadMore();
    return true;
  }
}

class _DisplayItem {
  const _DisplayItem({
    required this.item,
    required this.isSeller,
    required this.isHighlighted,
  });

  final dynamic item;
  final bool isSeller;
  final bool isHighlighted;
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  final ScrollController _scrollController = ScrollController();
  late final _PaginationController _paginationController;
  bool _isScrollListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _paginationController = _PaginationController(
      onLoadMore: () {
        setState(() {});
      },
    );
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
    _paginationController.handleScroll(_scrollController.position);
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
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 로딩 상태와 에러 상태 체크
    return Selector<CurrentTradeViewModel, ({bool isLoading, String? error})>(
      selector: (_, vm) => (isLoading: vm.isLoading, error: vm.error),
      builder: (context, state, _) {
        // 로딩 중일 때 빈 배경만 표시
        if (state.isLoading) {
          return Container();
        }
        
        // 에러가 있을 때
        if (state.error != null) {
          return TransparentRefreshIndicator(
            onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<CurrentTradeViewModel>().refresh(),
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
    return Selector<CurrentTradeViewModel, List<({bool isSeller, bool isHighlighted, dynamic item})>>(
      selector: (_, vm) => vm.allItems,
      builder: (context, allItems, _) {
        final horizontalPadding = context.hPadding;
        final verticalPadding = context.vPadding;
        final spacing = context.spacingSmall;
        
        // 빈 상태일 때
        if (allItems.isEmpty) {
          return TransparentRefreshIndicator(
            onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '현재 거래내역이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '새로운 상품을 등록하거나 입찰에 참여해보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // 데이터가 있을 때
        return TransparentRefreshIndicator(
          onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            itemCount: allItems.length + 1, // +1 for "전체 보기"
            itemBuilder: (context, index) {
              // "전체 보기" 링크
              if (index == allItems.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/mypage/trade'),
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
              
              // 일반 아이템
              final item = allItems[index];
              final useResponsive = MediaQuery.of(context).size.width >= 360;
              
              Widget card;
              if (item.isSeller) {
                final saleItem = item.item as SaleHistoryItem;
                card = TradeHistoryCard(
                  title: saleItem.title,
                  thumbnailUrl: saleItem.thumbnailUrl,
                  status: saleItem.status,
                  price: saleItem.price,
                  itemId: saleItem.itemId,
                  isSeller: true,
                  isHighlighted: item.isHighlighted,
                  useResponsive: useResponsive,
                );
              } else {
                final bidItem = item.item as BidHistoryItem;
                card = TradeHistoryCard(
                  title: bidItem.title,
                  thumbnailUrl: bidItem.thumbnailUrl,
                  status: bidItem.status,
                  price: bidItem.price,
                  itemId: bidItem.itemId,
                  isSeller: false,
                  isHighlighted: item.isHighlighted,
                  useResponsive: useResponsive,
                );
              }
              
              // 간격을 Container로 감싸서 안전하게 처리
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < allItems.length - 1 ? spacing : 0,
                ),
                child: card,
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
    return Selector<
      CurrentTradeViewModel,
      ({
        List<ActionHubItem> saleActionHubItems,
        List<ActionHubItem> bidActionHubItems,
        List<SaleHistoryItem> todoSaleItems,
        List<BidHistoryItem> todoBidItems,
        List<SaleHistoryItem> saleHistory,
        List<BidHistoryItem> bidHistory,
      })
    >(
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
