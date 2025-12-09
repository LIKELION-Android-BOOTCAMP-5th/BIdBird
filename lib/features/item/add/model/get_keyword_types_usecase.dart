import 'keyword_gateway.dart';
import 'keyword_type_entity.dart';

class GetKeywordTypesUseCase {
  GetKeywordTypesUseCase(this._gateway);

  final KeywordGateway _gateway;

  Future<List<KeywordTypeEntity>> call() {
    return _gateway.fetchKeywordTypes();
  }
}
