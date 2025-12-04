import 'dart:async';

import 'package:flutter/material.dart';

import '../data/current_trade_data.dart';
import '../repository/current_trade_repository.dart';

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
    if (status.contains('최고가 입찰') ||
        status.contains('즉시 구매') ||
        status == '낙찰') {
      return Colors.green;
    }
    if (status.contains('상위 입찰 발생')) {
      return Colors.orange;
    }
    if (status.contains('유찰') ||
        status.contains('패찰') ||
        status.contains('입찰 제한') ||
        status.contains('거래정지')) {
      return Colors.redAccent;
    }
    if (status.contains('입찰 없음')) {
      return Colors.grey;
    }
    return Colors.black54;
  }
}
