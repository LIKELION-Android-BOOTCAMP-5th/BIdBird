import 'package:bidbird/features/mypage/data/trade_history_repository.dart';
import 'package:bidbird/features/mypage/model/trade_history_model.dart';
import 'package:flutter/material.dart';

class TradeHistoryViewModel extends ChangeNotifier {
  TradeHistoryViewModel({required this.repository});

  final TradeHistoryRepository repository;

  TradeRole role = TradeRole.seller;
  int? statusFilter;
  int page = 1;
  final int pageSize = 20;
  bool isLoading = false;
  bool hasMore = true;
  String? errorMessage;
  final List<TradeHistoryItem> items = [];

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
      final result = await repository.fetchHistory(
        role: role,
        statusCode: statusFilter,
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
    statusFilter = null;
    loadPage(reset: true);
  }

  void changeFilter(int? code) {
    statusFilter = statusFilter == code ? null : code;
    loadPage(reset: true);
  }

  Future<void> refresh() async {
    await loadPage(reset: true); //당겨서새로고침RefreshIndicator
  }
}
