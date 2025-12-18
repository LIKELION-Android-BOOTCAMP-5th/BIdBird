import '../../domain/repositories/user_history_repository.dart';
import '../../domain/entities/user_history_entity.dart';
import '../datasources/user_history_datasource.dart';

class UserHistoryRepositoryImpl implements UserHistoryRepository {
  UserHistoryRepositoryImpl({UserHistoryDatasource? datasource})
      : _datasource = datasource ?? UserHistoryDatasource();

  final UserHistoryDatasource _datasource;

  @override
  Future<List<UserTradeSummary>> fetchUserTrades(String userId) {
    return _datasource.fetchUserTrades(userId);
  }
}



