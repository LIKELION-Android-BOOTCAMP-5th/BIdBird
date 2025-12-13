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

  Future<void> loadData() async {
    try {
      _setLoading(true);
      _error = null;

      _bidHistory = await _repository.fetchMyBidHistory();
      _saleHistory = await _repository.fetchMySaleHistory();

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
