import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';

/// Keyword 도메인 리포지토리 인터페이스
abstract class KeywordRepository {
  Future<List<KeywordTypeEntity>> fetchKeywordTypes();
}



