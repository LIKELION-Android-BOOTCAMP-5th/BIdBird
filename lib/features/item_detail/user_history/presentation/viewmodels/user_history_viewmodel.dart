import 'package:flutter/material.dart';
import '../../domain/entities/user_history_entity.dart';
import '../../domain/usecases/fetch_user_trades_usecase.dart';
import '../../data/repositories/user_history_repository.dart';

class UserHistoryViewModel extends ChangeNotifier {
  UserHistoryViewModel({FetchUserTradesUseCase? fetchUserTradesUseCase})
      : _fetchUserTradesUseCase =
            fetchUserTradesUseCase ?? FetchUserTradesUseCase(UserHistoryRepositoryImpl());

  final FetchUserTradesUseCase _fetchUserTradesUseCase;

  List<UserTradeSummary> _trades = [];
  bool _isLoading = false;

  List<UserTradeSummary> get trades => _trades;
  bool get isLoading => _isLoading;

  Future<void> loadTrades(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _trades = await _fetchUserTradesUseCase(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}



