import '../entities/user_history_entity.dart';

abstract class UserHistoryRepository {
  Future<List<UserTradeSummary>> fetchUserTrades(String userId);
}



