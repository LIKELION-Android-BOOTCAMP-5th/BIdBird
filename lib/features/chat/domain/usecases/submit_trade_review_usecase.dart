import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 거래 리뷰 제출 유즈케이스
class SubmitTradeReviewUseCase {
  SubmitTradeReviewUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({
    required String itemId,
    required String toUserId,
    required String role,
    required double rating,
    required String comment,
  }) {
    return _repository.submitTradeReview(
      itemId: itemId,
      toUserId: toUserId,
      role: role,
      rating: rating,
      comment: comment,
    );
  }
}

