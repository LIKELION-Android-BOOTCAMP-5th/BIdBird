import 'dart:async';

import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';

import '../data/repository/current_trade_repository.dart';
import '../model/current_trade_entity.dart';

class CurrentTradeViewModel extends ItemBaseViewModel {
  final CurrentTradeRepository _repository;

  List<BidHistoryItem> _bidHistory = [];
  List<SaleHistoryItem> _saleHistory = [];
  
  // 캐싱 관련
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  // 필터링 결과 캐시
  List<BidHistoryItem>? _cachedTodoBidItems;
  List<BidHistoryItem>? _cachedInProgressBidItems;
  List<BidHistoryItem>? _cachedCompletedBidItems;
  List<SaleHistoryItem>? _cachedTodoSaleItems;
  List<SaleHistoryItem>? _cachedInProgressSaleItems;
  List<SaleHistoryItem>? _cachedCompletedSaleItems;
  List<ActionHubItem>? _cachedBidActionHubItems;
  List<ActionHubItem>? _cachedSaleActionHubItems;

  CurrentTradeViewModel({required CurrentTradeRepository repository})
    : _repository = repository;

  List<BidHistoryItem> get bidHistory => _bidHistory;
  List<SaleHistoryItem> get saleHistory => _saleHistory;

  /// 상태별 그룹핑된 아이템 (구매 내역) - 캐싱 적용
  List<BidHistoryItem> get todoBidItems {
    _cachedTodoBidItems ??= _filterByStatus(_bidHistory, TradeItemStatus.todo);
    return _cachedTodoBidItems!;
  }

  List<BidHistoryItem> get inProgressBidItems {
    _cachedInProgressBidItems ??= 
        _filterByStatus(_bidHistory, TradeItemStatus.inProgress);
    return _cachedInProgressBidItems!;
  }

  List<BidHistoryItem> get completedBidItems {
    _cachedCompletedBidItems ??= 
        _filterByStatus(_bidHistory, TradeItemStatus.completed);
    return _cachedCompletedBidItems!;
  }

  /// 상태별 그룹핑된 아이템 (판매 내역) - 캐싱 적용
  List<SaleHistoryItem> get todoSaleItems {
    _cachedTodoSaleItems ??= 
        _filterByStatus(_saleHistory, TradeItemStatus.todo);
    return _cachedTodoSaleItems!;
  }

  List<SaleHistoryItem> get inProgressSaleItems {
    _cachedInProgressSaleItems ??= 
        _filterByStatus(_saleHistory, TradeItemStatus.inProgress);
    return _cachedInProgressSaleItems!;
  }

  List<SaleHistoryItem> get completedSaleItems {
    _cachedCompletedSaleItems ??= 
        _filterByStatus(_saleHistory, TradeItemStatus.completed);
    return _cachedCompletedSaleItems!;
  }

  /// 상태별로 아이템 필터링하는 제네릭 헬퍼 메서드
  List<T> _filterByStatus<T extends TradeHistoryItem>(List<T> items, TradeItemStatus status) {
    return items.where((item) => item.itemStatus == status).toList();
  }

  /// 액션 허브 아이템 (구매 내역, 최대 2개) - 캐싱 적용
  List<ActionHubItem> get bidActionHubItems {
    _cachedBidActionHubItems ??= _buildActionHubItems(
      _bidHistory,
      [TradeActionType.paymentRequired, TradeActionType.purchaseConfirmRequired],
    );
    return _cachedBidActionHubItems!;
  }

  /// 액션 허브 아이템 (판매 내역, 최대 2개) - 캐싱 적용
  List<ActionHubItem> get saleActionHubItems {
    _cachedSaleActionHubItems ??= _buildActionHubItems(
      _saleHistory,
      [TradeActionType.paymentRequired, TradeActionType.shippingInfoRequired],
    );
    return _cachedSaleActionHubItems!;
  }

  /// 액션 허브 아이템 생성 헬퍼 메서드
  List<ActionHubItem> _buildActionHubItems(
    List<TradeHistoryItem> items,
    List<TradeActionType> targetActionTypes,
  ) {
    final Map<TradeActionType, int> actionCounts = {
      for (final type in targetActionTypes) type: 0,
    };
    
    for (final item in items) {
      final actionType = item.actionType;
      if (actionType != TradeActionType.none && actionCounts.containsKey(actionType)) {
        actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
      }
    }

    final hubItems = actionCounts.entries
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();
    
    hubItems.sort((a, b) => b.count.compareTo(a.count));
    return hubItems.take(2).toList();
  }

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
        _repository.fetchMyBidHistory(),
        _repository.fetchMySaleHistory(),
      ], eagerError: false);

      _bidHistory = results[0] as List<BidHistoryItem>;
      _saleHistory = results[1] as List<SaleHistoryItem>;
      
      // 필터링 결과 캐시 무효화
      _invalidateFilterCache();
      
      updateCacheTime();

      notifyListeners();
    } catch (e) {
      stopLoadingWithError(e.toString());
      // 에러 발생 시에도 캐시된 데이터는 유지
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
    _cachedBidActionHubItems = null;
    _cachedSaleActionHubItems = null;
  }
}
