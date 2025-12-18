import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/repositories/keyword_repository.dart';

class GetKeywordTypesUseCase {
  GetKeywordTypesUseCase(this._repository);

  final KeywordRepository _repository;

  Future<List<KeywordTypeEntity>> call() {
    return _repository.fetchKeywordTypes();
  }
}
