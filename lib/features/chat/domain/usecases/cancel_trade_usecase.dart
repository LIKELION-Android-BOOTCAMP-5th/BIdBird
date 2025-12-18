import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 거래 취소 유즈케이스
class CancelTradeUseCase {
  CancelTradeUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String itemId, String reasonCode, bool isSellerFault) {
    return _repository.cancelTrade(itemId, reasonCode, isSellerFault);
  }
}

