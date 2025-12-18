import 'package:bidbird/features/item_enroll/add/data/datasources/keyword_datasource.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/repositories/keyword_repository.dart' as domain;

/// Keyword 리포지토리 구현체
class KeywordRepositoryImpl implements domain.KeywordRepository {
  KeywordRepositoryImpl({KeywordDatasource? datasource})
      : _datasource = datasource ?? KeywordDatasource();

  final KeywordDatasource _datasource;

  @override
  Future<List<KeywordTypeEntity>> fetchKeywordTypes() {
    return _datasource.fetchKeywordTypes();
  }
}
