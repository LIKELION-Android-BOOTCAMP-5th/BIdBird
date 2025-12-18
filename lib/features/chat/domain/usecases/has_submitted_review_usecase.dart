import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 리뷰 제출 여부 확인 유즈케이스
class HasSubmittedReviewUseCase {
  HasSubmittedReviewUseCase(this._repository);

  final ChatRepository _repository;

  Future<bool> call(String itemId) {
    return _repository.hasSubmittedReview(itemId);
  }
}

