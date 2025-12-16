import 'package:flutter/material.dart';
import 'package:bidbird/features/item/user_history/data/datasource/user_history_datasource.dart';
import 'package:bidbird/features/item/user_history/model/user_history_entity.dart';

class UserHistoryViewModel extends ChangeNotifier {
  UserHistoryViewModel({UserHistoryDatasource? datasource})
      : _datasource = datasource ?? UserHistoryDatasource();

  final UserHistoryDatasource _datasource;

  List<UserTradeSummary> _trades = [];

  List<UserTradeSummary> get trades => _trades;

  Future<void> loadTrades(String userId) async {
    _trades = await _datasource.fetchUserTrades(userId);
    notifyListeners();
  }
}
