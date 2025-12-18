import 'package:bidbird/features/item_detail/user_history/domain/entities/user_history_entity.dart';
import 'package:bidbird/features/item_detail/user_history/domain/repositories/user_history_repository.dart';

/// 사용자 거래 내역 조회 유즈케이스
class FetchUserTradesUseCase {
  FetchUserTradesUseCase(this._repository);

  final UserHistoryRepository _repository;

  Future<List<UserTradeSummary>> call(String userId) {
    return _repository.fetchUserTrades(userId);
  }
}

