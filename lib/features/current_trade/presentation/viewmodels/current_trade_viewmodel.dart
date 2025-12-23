import 'dart:async';

import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/current_trade/data/repositories/current_trade_repository.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/usecases/fetch_my_bid_history_usecase.dart';
import 'package:bidbird/features/current_trade/domain/usecases/fetch_my_sale_history_usecase.dart';

/// CurrentTrade ViewModel - Thin Pattern
/// 책임: 거래 내역 UI 상태 관리, 필터링/캠싱
/// 제외: 복잡한 비즈니스 로직 (UseCase에서 처리)
class CurrentTradeViewModel extends ItemBaseViewModel {
  final FetchMyBidHistoryUseCase _fetchMyBidHistoryUseCase;
  final FetchMySaleHistoryUseCase _fetchMySaleHistoryUseCase;

  List<BidHistoryItem> _bidHistory = [];
  List<SaleHistoryItem> _saleHistory = [];

  // State: Caching
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  // 필터링 결과 캐시
  List<BidHistoryItem>? _cachedTodoBidItems;
  List<BidHistoryItem>? _cachedInProgressBidItems;
  List<BidHistoryItem>? _cachedCompletedBidItems;
  List<SaleHistoryItem>? _cachedTodoSaleItems;
  List<SaleHistoryItem>? _cachedInProgressSaleItems;
  List<SaleHistoryItem>? _cachedCompletedSaleItems;
  List<BidHistoryItem>? _cachedFilteredBidItems;
  List<SaleHistoryItem>? _cachedFilteredSaleItems;
  List<ActionHubItem>? _cachedBidActionHubItems;
  List<ActionHubItem>? _cachedSaleActionHubItems;
  List<({bool isSeller, bool isHighlighted, dynamic item})>? _cachedAllItems;
  
  // State: UI Status
  int _pendingActionCount = 0;
  int _acknowledgedPendingCount = 0;

  CurrentTradeViewModel({
    FetchMyBidHistoryUseCase? fetchMyBidHistoryUseCase,
    FetchMySaleHistoryUseCase? fetchMySaleHistoryUseCase,
  }) : _fetchMyBidHistoryUseCase =
           fetchMyBidHistoryUseCase ??
           FetchMyBidHistoryUseCase(CurrentTradeRepositoryImpl()),
       _fetchMySaleHistoryUseCase =
           fetchMySaleHistoryUseCase ??
           FetchMySaleHistoryUseCase(CurrentTradeRepositoryImpl());

  List<BidHistoryItem> get bidHistory => _bidHistory;
  List<SaleHistoryItem> get saleHistory => _saleHistory;

  // Computed: Filtered Items by Status
  List<BidHistoryItem> get todoBidItems {
    _cachedTodoBidItems ??= _filterByStatus(_bidHistory, TradeItemStatus.todo);
    return _cachedTodoBidItems!;
  }

  List<BidHistoryItem> get inProgressBidItems {
    _cachedInProgressBidItems ??= _filterByStatus(
      _bidHistory,
      TradeItemStatus.inProgress,
    );
    return _cachedInProgressBidItems!;
  }

  List<BidHistoryItem> get completedBidItems {
    _cachedCompletedBidItems ??= _filterByStatus(
      _bidHistory,
      TradeItemStatus.completed,
    );
    return _cachedCompletedBidItems!;
  }


  List<SaleHistoryItem> get todoSaleItems {
    _cachedTodoSaleItems ??= _filterByStatus(
      _saleHistory,
      TradeItemStatus.todo,
    );
    return _cachedTodoSaleItems!;
  }

  List<SaleHistoryItem> get inProgressSaleItems {
    _cachedInProgressSaleItems ??= _filterByStatus(
      _saleHistory,
      TradeItemStatus.inProgress,
    );
    return _cachedInProgressSaleItems!;
  }

  List<SaleHistoryItem> get completedSaleItems {
    _cachedCompletedSaleItems ??= _filterByStatus(
      _saleHistory,
      TradeItemStatus.completed,
    );
    return _cachedCompletedSaleItems!;
  }

  /// 현재 처리해야 할 거래가 존재하는지 여부 (미확인 건 기준)
  bool get hasPendingTradeAction {
    return _pendingActionCount > _acknowledgedPendingCount;
  }

  void markPendingActionsAcknowledged() {
    final changed = _pendingActionCount > _acknowledgedPendingCount;
    _acknowledgedPendingCount = _pendingActionCount;
    if (changed) {
      notifyListeners();
    }
  }


  List<SaleHistoryItem> get filteredSaleItems {
    _cachedFilteredSaleItems ??= [
      ...todoSaleItems,
      ...inProgressSaleItems,
      ...completedSaleItems,
    ].where((item) => !item.status.contains('유찰')).toList();
    return _cachedFilteredSaleItems!;
  }


  List<BidHistoryItem> get filteredBidItems {
    _cachedFilteredBidItems ??= [
      ...todoBidItems,
      ...inProgressBidItems,
      ...completedBidItems,
    ].where((item) => !item.status.contains('유찰')).toList();
    return _cachedFilteredBidItems!;
  }


  List<({bool isSeller, bool isHighlighted, dynamic item})> get allItems {
    _cachedAllItems ??= [
      // 판매 아이템 추가
      for (var item in filteredSaleItems)
        (
          isSeller: true,
          isHighlighted: item.itemStatus == TradeItemStatus.todo,
          item: item,
        ),
      // 입찰 아이템 추가
      for (var item in filteredBidItems)
        (
          isSeller: false,
          isHighlighted: item.itemStatus == TradeItemStatus.todo,
          item: item,
        ),
    ];
    return _cachedAllItems!;
  }

  List<T> _filterByStatus<T extends TradeHistoryItem>(
    List<T> items,
    TradeItemStatus status,
  ) {
    return items.where((item) => item.itemStatus == status).toList();
  }


  List<ActionHubItem> get bidActionHubItems {
    _cachedBidActionHubItems ??= _buildActionHubItems(_bidHistory, [
      TradeActionType.paymentRequired,
      TradeActionType.purchaseConfirmRequired,
    ]);
    return _cachedBidActionHubItems!;
  }


  List<ActionHubItem> get saleActionHubItems {
    _cachedSaleActionHubItems ??= _buildActionHubItems(_saleHistory, [
      TradeActionType.paymentWaiting,
      TradeActionType.shippingInfoRequired,
    ]);
    return _cachedSaleActionHubItems!;
  }

  List<ActionHubItem> _buildActionHubItems(
    List<TradeHistoryItem> items,
    List<TradeActionType> targetActionTypes,
  ) {
    final Map<TradeActionType, int> actionCounts = {
      for (final type in targetActionTypes) type: 0,
    };

    for (final item in items) {
      final actionType = item.actionType;
      if (actionType != TradeActionType.none &&
          actionCounts.containsKey(actionType)) {
        actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
      }
    }

    final hubItems = actionCounts.entries
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();

    hubItems.sort((a, b) => b.count.compareTo(a.count));
    return hubItems.take(2).toList();
  }

  // Methods: Data Loading
  Future<void> loadData({bool forceRefresh = false}) async {
    if (isLoading) {
      return;
    }

    // 캐시가 유효하고 강제 새로고침이 아니면 캐시 사용
    if (!forceRefresh &&
        isCacheValid(_cacheValidDuration) &&
        _bidHistory.isNotEmpty &&
        _saleHistory.isNotEmpty) {
      return; // 캐시된 데이터 사용
    }

    try {
      startLoading();

      // 병렬로 입찰/판매 내역 조회 - 일부 실패해도 다른 요청은 계속 진행
      final results = await Future.wait([
        _fetchMyBidHistoryUseCase(),
        _fetchMySaleHistoryUseCase(),
      ], eagerError: false);

      _bidHistory = results[0] as List<BidHistoryItem>;
      _saleHistory = results[1] as List<SaleHistoryItem>;


      _invalidateFilterCache();

      updateCacheTime();

      _pendingActionCount = _calculatePendingActionCount();
      if (_acknowledgedPendingCount > _pendingActionCount) {
        _acknowledgedPendingCount = _pendingActionCount;
      }
      notifyListeners();
    } catch (e) {
      stopLoadingWithError(e.toString());

    } finally {
      stopLoading();
    }
  }

  Future<void> refresh() async {
    await loadData(forceRefresh: true);
  }

  /// 필터링 결과 캐시 무효화
  void _invalidateFilterCache() {
    _cachedTodoBidItems = null;
    _cachedInProgressBidItems = null;
    _cachedCompletedBidItems = null;
    _cachedTodoSaleItems = null;
    _cachedInProgressSaleItems = null;
    _cachedCompletedSaleItems = null;
    _cachedFilteredBidItems = null;
    _cachedFilteredSaleItems = null;
    _cachedAllItems = null;
    _cachedBidActionHubItems = null;
    _cachedSaleActionHubItems = null;
  }

  int _calculatePendingActionCount() {
    int count = 0;

    for (final item in _saleHistory) {
      final statusCode = item.tradeStatusCode;
      if (statusCode == TradeStatusCode.paymentRequired) {
        count++;
        continue;
      }
      if (statusCode == TradeStatusCode.shippingInfoRequired &&
          !item.hasShippingInfo) {
        count++;
      }
    }

    for (final item in _bidHistory) {
      final statusCode = item.tradeStatusCode;
      if (statusCode == TradeStatusCode.paymentRequired) {
        count++;
        continue;
      }
      if (statusCode == TradeStatusCode.shippingInfoRequired &&
          item.hasShippingInfo) {
        count++;
        continue;
      }
      if ((statusCode == null || statusCode == 0) &&
          item.auctionStatusCode == AuctionStatusCode.bidWon) {
        count++;
      }
    }

    return count;
  }
}
