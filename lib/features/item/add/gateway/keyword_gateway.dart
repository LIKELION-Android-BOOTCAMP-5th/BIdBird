import 'package:bidbird/features/item/add/model/keyword_type_entity.dart';

abstract class KeywordGateway {
  Future<List<KeywordTypeEntity>> fetchKeywordTypes();
}
