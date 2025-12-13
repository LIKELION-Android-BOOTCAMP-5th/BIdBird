import '../datasource/user_history_data.dart';
import '../../model/user_history_entity.dart';

class UserHistoryRepository {
  UserHistoryRepository({UserHistoryDatasource? datasource})
      : _datasource = datasource ?? UserHistoryDatasource();

  final UserHistoryDatasource _datasource;

  Future<List<UserTradeSummary>> fetchUserTrades(String userId) {
    return _datasource.fetchUserTrades(userId);
  }
}
