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
    // 로딩 상태만 Selector
    return Selector<CurrentTradeViewModel, bool>(
      selector: (_, vm) => vm.isLoading,
      builder: (context, isLoading, _) {
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error, style: const TextStyle(color: Colors.red)),
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
    // ViewModel의 캐싱된 통합 리스트를 직접 사용하도록 Selector 구성
    return Selector<CurrentTradeViewModel, List<({bool isSeller, bool isHighlighted, dynamic item})>>(
      selector: (_, vm) => vm.allItems,
      builder: (context, allItems, _) {
        final totalItemCount = allItems.length;

        if (totalItemCount == 0) {
          return RefreshIndicator(
            onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
            child: const SizedBox.shrink(),
          );
        }

        return TransparentRefreshIndicator(
          onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
          child: Builder(
            builder: (context) {
              final horizontalPadding = context.hPadding;
              final verticalPadding = context.vPadding;
              final spacing = context.spacingSmall;

              final initialVisibleCount =
                  VisibleItemCalculator.calculateTradeHistoryVisibleCount(
                    context,
                  );
              _paginationController.updateTotals(
                totalCount: totalItemCount,
                initialVisibleCount: initialVisibleCount,
              );

              final displayCount = _paginationController.displayedCount;
              final displayItems = allItems
                  .take(displayCount)
                  .map((item) => _DisplayItem(
                        item: item.item,
                        isSeller: item.isSeller,
                        isHighlighted: item.isHighlighted,
                      ))
                  .toList(growable: false);
              final hasMore = _paginationController.hasMore;

              return ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                itemCount: displayItems.length + (hasMore ? 1 : 0) + 1,
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
                        child: _paginationController.isLoadingMore
                            ? const CircularProgressIndicator()
                            : const SizedBox.shrink(),
                      ),
                    );
                  }

                  final itemData = displayItems[index];
                  final useResponsive = MediaQuery.of(context).size.width >= 360;

                  if (itemData.isSeller) {
                    final saleItem = itemData.item as SaleHistoryItem;
                    return TradeHistoryCard(
                      title: saleItem.title,
                      thumbnailUrl: saleItem.thumbnailUrl,
                      status: saleItem.status,
                      price: saleItem.price,
                      itemId: saleItem.itemId,
                      isSeller: true,
                      isHighlighted: itemData.isHighlighted,
                      useResponsive: useResponsive,
                    );
                  } else {
                    final bidItem = itemData.item as BidHistoryItem;
                    return TradeHistoryCard(
                      title: bidItem.title,
                      thumbnailUrl: bidItem.thumbnailUrl,
                      status: bidItem.status,
                      price: bidItem.price,
                      itemId: bidItem.itemId,
                      isSeller: false,
                      isHighlighted: itemData.isHighlighted,
                      useResponsive: useResponsive,
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
