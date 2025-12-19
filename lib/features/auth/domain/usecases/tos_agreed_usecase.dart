import '../repositories/tos_repository.dart';

/// ToS 동의 처리 유즈케이스
class ToSAgreedUseCase {
  ToSAgreedUseCase(this._repository);

  final ToSRepository _repository;

  Future<void> call() {
    return _repository.tosAgreed();
  }
}


