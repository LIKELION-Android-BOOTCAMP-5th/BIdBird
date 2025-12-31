import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/entities/trade_history_entity.dart';
import '../domain/usecases/get_trade_history.dart';

class TradeHistoryViewModel extends ChangeNotifier {
  TradeHistoryViewModel({required GetTradeHistory getTradeHistory})
    : _getTradeHistory = getTradeHistory;

  final GetTradeHistory _getTradeHistory;

  TradeRole role = TradeRole.seller;
  List<int>? statusFilters;
  int page = 1;
  final int pageSize = 20;
  bool isLoading = false;
  bool hasMore = true;
  String? errorMessage;
  final List<TradeHistoryEntity> items = [];

  //page말고더정확한다른방식알아보기
  Future<void> loadPage({bool reset = false}) async {
    if (isLoading) return; //반복요청대비

    if (reset) {
      page = 1;
      hasMore = true;
      items.clear();
    }

    if (!hasMore) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _getTradeHistory(
        role: role,
        statusCodes: statusFilters,
        page: page,
        pageSize: pageSize,
      );
      items.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void changeRole(TradeRole newRole) {
    if (role == newRole) return; //반복방지
    role = newRole;
    statusFilters = null;
    loadPage(reset: true);
  }

  void changeFilter(List<int> codes) {
    statusFilters = listEquals(statusFilters, codes)
        ? null
        : List<int>.from(codes);
    loadPage(reset: true);
  }

  Future<void> refresh() async {
    await loadPage(reset: true); //당겨서새로고침RefreshIndicator
  }
}
