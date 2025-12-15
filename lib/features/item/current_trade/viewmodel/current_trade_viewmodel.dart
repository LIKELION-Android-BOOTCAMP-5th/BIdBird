import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repository/current_trade_repository.dart';
import '../model/current_trade_entity.dart';

class CurrentTradeViewModel extends ChangeNotifier {
  final CurrentTradeRepository _repository;

  List<BidHistoryItem> _bidHistory = [];
  List<SaleHistoryItem> _saleHistory = [];
  bool _isLoading = false;
  String? _error;
  
  // 캐싱 관련
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  CurrentTradeViewModel({required CurrentTradeRepository repository})
    : _repository = repository;

  List<BidHistoryItem> get bidHistory => _bidHistory;
  List<SaleHistoryItem> get saleHistory => _saleHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 상태별 그룹핑된 아이템 (구매 내역)
  List<BidHistoryItem> get todoBidItems => 
      _filterByStatus(_bidHistory, TradeItemStatus.todo);

  List<BidHistoryItem> get inProgressBidItems => 
      _filterByStatus(_bidHistory, TradeItemStatus.inProgress);

  List<BidHistoryItem> get completedBidItems => 
      _filterByStatus(_bidHistory, TradeItemStatus.completed);

  /// 상태별 그룹핑된 아이템 (판매 내역)
  List<SaleHistoryItem> get todoSaleItems => 
      _filterByStatus(_saleHistory, TradeItemStatus.todo);

  List<SaleHistoryItem> get inProgressSaleItems => 
      _filterByStatus(_saleHistory, TradeItemStatus.inProgress);

  List<SaleHistoryItem> get completedSaleItems => 
      _filterByStatus(_saleHistory, TradeItemStatus.completed);

  /// 상태별로 아이템 필터링하는 제네릭 헬퍼 메서드
  List<T> _filterByStatus<T extends TradeHistoryItem>(List<T> items, TradeItemStatus status) {
    return items.where((item) => item.itemStatus == status).toList();
  }

  /// 액션 허브 아이템 (구매 내역, 최대 2개)
  List<ActionHubItem> get bidActionHubItems {
    return _buildActionHubItems(
      _bidHistory,
      [TradeActionType.paymentRequired, TradeActionType.purchaseConfirmRequired],
    );
  }

  /// 액션 허브 아이템 (판매 내역, 최대 2개)
  List<ActionHubItem> get saleActionHubItems {
    return _buildActionHubItems(
      _saleHistory,
      [TradeActionType.paymentRequired, TradeActionType.shippingInfoRequired],
    );
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
    if (_isLoading) {
      return;
    }
    
    // 캐시가 유효하고 강제 새로고침이 아니면 캐시 사용
    if (!forceRefresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
        _bidHistory.isNotEmpty && 
        _saleHistory.isNotEmpty) {
      return; // 캐시된 데이터 사용
    }
    
    try {
      _setLoading(true);
      _error = null;

      // 병렬로 입찰/판매 내역 조회 - 일부 실패해도 다른 요청은 계속 진행
      final results = await Future.wait([
        _repository.fetchMyBidHistory(),
        _repository.fetchMySaleHistory(),
      ], eagerError: false);

      _bidHistory = results[0] as List<BidHistoryItem>;
      _saleHistory = results[1] as List<SaleHistoryItem>;
      
      _lastFetchTime = DateTime.now();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // 에러 발생 시에도 캐시된 데이터는 유지
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await loadData(forceRefresh: true);
  }
  
  /// 캐시 무효화
  void invalidateCache() {
    _lastFetchTime = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
