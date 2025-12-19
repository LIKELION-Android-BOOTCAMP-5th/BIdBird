import '../entities/tos_entity.dart';
import '../repositories/tos_repository.dart';

/// ToS 정보 조회 유즈케이스
class GetToSInfoUseCase {
  GetToSInfoUseCase(this._repository);

  final ToSRepository _repository;

  Future<List<ToSEntity>> call() {
    return _repository.getToSinfo();
  }
}


