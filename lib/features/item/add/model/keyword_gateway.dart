import 'keyword_type_entity.dart';

abstract class KeywordGateway {
  Future<List<KeywordTypeEntity>> fetchKeywordTypes();
}
