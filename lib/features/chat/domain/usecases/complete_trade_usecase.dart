import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 거래 완료 유즈케이스
class CompleteTradeUseCase {
  CompleteTradeUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String itemId) {
    return _repository.completeTrade(itemId);
  }
}

