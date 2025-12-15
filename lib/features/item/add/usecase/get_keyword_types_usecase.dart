import 'package:bidbird/features/item/add/gateway/keyword_gateway.dart';
import 'package:bidbird/features/item/add/model/keyword_type_entity.dart';

class GetKeywordTypesUseCase {
  GetKeywordTypesUseCase(this._gateway);

  final KeywordGateway _gateway;

  Future<List<KeywordTypeEntity>> call() {
    return _gateway.fetchKeywordTypes();
  }
}
