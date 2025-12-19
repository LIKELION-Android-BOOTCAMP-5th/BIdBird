import '../repositories/home_repository.dart';

class GetKeywordTypeUseCase {
  GetKeywordTypeUseCase(this._repository);

  final HomeRepository _repository;

  Future<void> call() {
    return _repository.getKeywordType();
  }
}
