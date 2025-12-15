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

  CurrentTradeViewModel({required CurrentTradeRepository repository})
    : _repository = repository;

  List<BidHistoryItem> get bidHistory => _bidHistory;
  List<SaleHistoryItem> get saleHistory => _saleHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 상태별 그룹핑된 아이템 (구매 내역)
  List<BidHistoryItem> get todoBidItems {
    return _bidHistory.where((item) => item.itemStatus == TradeItemStatus.todo).toList();
  }

  List<BidHistoryItem> get inProgressBidItems {
    return _bidHistory.where((item) => item.itemStatus == TradeItemStatus.inProgress).toList();
  }

  List<BidHistoryItem> get completedBidItems {
    return _bidHistory.where((item) => item.itemStatus == TradeItemStatus.completed).toList();
  }

  /// 상태별 그룹핑된 아이템 (판매 내역)
  List<SaleHistoryItem> get todoSaleItems {
    return _saleHistory.where((item) => item.itemStatus == TradeItemStatus.todo).toList();
  }

  List<SaleHistoryItem> get inProgressSaleItems {
    return _saleHistory.where((item) => item.itemStatus == TradeItemStatus.inProgress).toList();
  }

  List<SaleHistoryItem> get completedSaleItems {
    return _saleHistory.where((item) => item.itemStatus == TradeItemStatus.completed).toList();
  }

  /// 액션 허브 아이템 (구매 내역, 최대 2개)
  List<ActionHubItem> get bidActionHubItems {
    final Map<TradeActionType, int> actionCounts = {
      TradeActionType.paymentRequired: 0,
      TradeActionType.purchaseConfirmRequired: 0,
    };
    
    for (final item in _bidHistory) {
      final actionType = item.actionType;
      if (actionType != TradeActionType.none) {
        actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
      }
    }

    final hubItems = actionCounts.entries
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();
    
    hubItems.sort((a, b) => b.count.compareTo(a.count));
    return hubItems.take(2).toList();
  }

  /// 액션 허브 아이템 (판매 내역, 최대 2개)
  List<ActionHubItem> get saleActionHubItems {
    final Map<TradeActionType, int> actionCounts = {
      TradeActionType.paymentRequired: 0,
      TradeActionType.shippingInfoRequired: 0,
    };
    
    for (final item in _saleHistory) {
      final actionType = item.actionType;
      if (actionType != TradeActionType.none) {
        actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
      }
    }

    final hubItems = actionCounts.entries
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();
    
    hubItems.sort((a, b) => b.count.compareTo(a.count));
    return hubItems.take(2).toList();
  }

  Future<void> loadData() async {
    try {
      _setLoading(true);
      _error = null;

      // 병렬로 입찰/판매 내역 조회
      final results = await Future.wait([
        _repository.fetchMyBidHistory(),
        _repository.fetchMySaleHistory(),
      ]);

      _bidHistory = results[0] as List<BidHistoryItem>;
      _saleHistory = results[1] as List<SaleHistoryItem>;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
