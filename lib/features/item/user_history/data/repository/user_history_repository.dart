import '../datasource/user_history_data.dart';
import '../../model/user_history_entity.dart';

class UserProfileRepository {
  UserProfileRepository({UserProfileDatasource? datasource})
      : _datasource = datasource ?? UserProfileDatasource();

  final UserProfileDatasource _datasource;

  Future<List<UserTradeSummary>> fetchUserTrades(String userId) {
    return _datasource.fetchUserTrades(userId);
  }
}
