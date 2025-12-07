import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';

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

  Future<void> loadData() async {
    try {
      _setLoading(true);
      _error = null;

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

  static Color getStatusColor(String status) {
    // 경매 등록: 파란색
    if (status.contains('경매 등록')) {
      return blueColor;
    }

    // 경매/입찰 진행 중 또는 성공 계열: 초록색
    if (status.contains('경매 진행 중') ||
        status.contains('입찰 중') ||
        status.contains('최고가 입찰') ||
        status.contains('입찰 성공') ||
        status.contains('즉시 구매 진행 중') ||
        status == '낙찰') {
      return Colors.green;
    }

    // 상위 입찰 발생: 주황색
    if (status.contains('상위 입찰 발생')) {
      return Colors.orange;
    }

    // 실패/제한 계열: 빨간색
    if (status.contains('유찰') ||
        status.contains('패찰') ||
        status.contains('입찰 제한') ||
        status.contains('거래정지') ||
        status.contains('결제 실패') ||
        status.contains('결제 실패 횟수 초과') ||
        status.contains('현재가보다 낮은 입찰')) {
      return Colors.redAccent;
    }

    // 종료/완료 계열: 회색
    if (status.contains('경매 종료') ||
        status.contains('경매 종료 후 입찰') ||
        status.contains('즉시 구매 완료') ||
        status.contains('입찰 없음')) {
      return Colors.grey;
    }

    return Colors.black54;
  }
}
