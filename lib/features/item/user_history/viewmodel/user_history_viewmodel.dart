import 'package:flutter/material.dart';

import '../data/repository/user_history_repository.dart';
import '../model/user_history_entity.dart';

class UserHistoryViewModel extends ChangeNotifier {
  UserHistoryViewModel({UserHistoryRepository? repository})
      : _repository = repository ?? UserHistoryRepository();

  final UserHistoryRepository _repository;

  List<UserTradeSummary> _trades = [];

  List<UserTradeSummary> get trades => _trades;

  Future<void> loadTrades(String userId) async {
    _trades = await _repository.fetchUserTrades(userId);
    notifyListeners();
  }
}
